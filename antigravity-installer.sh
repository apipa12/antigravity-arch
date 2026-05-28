#!/usr/bin/env bash
# ==============================================================================
# antigravity-installer.sh
# Installs or updates Google Antigravity (Hub or IDE) on Arch-based systems.
#
# Supported products:
#   Antigravity Hub  — pure agentic platform (2.0+), no built-in code editor
#   Antigravity IDE  — VS Code-fork IDE with integrated agent (2.0+)
#
# Usage:
#   ./antigravity-installer.sh                      Install / update Antigravity Hub
#   ./antigravity-installer.sh --ide                Install / update Antigravity IDE
#   ./antigravity-installer.sh --uninstall          Uninstall Antigravity Hub
#   ./antigravity-installer.sh --ide --uninstall    Uninstall Antigravity IDE
#
# Requirements: curl, tar, b2sum (all available in Arch base / base-devel)
# Optional:     wget (for cleaner download progress rendering)
# ==============================================================================
set -euo pipefail


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1 — CONFIGURATION
# All product-specific constants and paths are defined here.
# ══════════════════════════════════════════════════════════════════════════════

# AUR .SRCINFO URLs — source of truth for version, tarball URL, and checksum
readonly AUR_SRCINFO_HUB="https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=antigravity"
readonly AUR_SRCINFO_IDE="https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=antigravity-ide"

# AUR icon source for the Hub (icon is not bundled inside the Hub tarball)
readonly HUB_ICON_URL="https://aur.archlinux.org/cgit/aur.git/plain/antigravity.png?h=antigravity"

# Icon sizes to install into the hicolor theme (covers all common DE queries)
readonly ICON_SIZES=(1024x1024 512x512 256x256)

# XDG base paths
readonly XDG_LOCAL_BIN="${HOME}/.local/bin"
readonly XDG_APPLICATIONS="${HOME}/.local/share/applications"
readonly XDG_ICONS="${HOME}/.local/share/icons/hicolor"
readonly INSTALL_ROOT="${HOME}/Applications"

# Legacy v1 system-wide install paths (cleaned up automatically on install)
readonly LEGACY_OPT_DIR="/opt/antigravity"
readonly LEGACY_BIN="/usr/local/bin/antigravity"
readonly LEGACY_DESKTOP_1="/usr/share/applications/antigravity.desktop"
readonly LEGACY_DESKTOP_2="/usr/share/applications/antigravity-url-handler.desktop"
readonly LEGACY_ICON="/usr/share/pixmaps/antigravity.png"


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2 — ARGUMENT PARSING & PRODUCT SELECTION
# Selects between Hub and IDE and sets all product-specific variables.
# ══════════════════════════════════════════════════════════════════════════════

INSTALL_IDE=false
UNINSTALL=false

for arg in "${@}"; do
  case "$arg" in
    --ide)       INSTALL_IDE=true  ;;
    --uninstall) UNINSTALL=true    ;;
    *) printf '[-] Unknown argument: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

if $INSTALL_IDE; then
  APP_NAME="Antigravity IDE"
  APP_ID="antigravity-ide"
  SRCINFO_URL="$AUR_SRCINFO_IDE"
  APP_EXECUTABLE="antigravity-ide"
  INSTALL_DIR="${INSTALL_ROOT}/AntigravityIDE"
  # IDE icon is bundled inside the tarball at this path (1024x1024 PNG)
  BUNDLED_ICON_RELPATH="resources/app/resources/linux/code.png"
else
  APP_NAME="Antigravity"
  APP_ID="antigravity"
  SRCINFO_URL="$AUR_SRCINFO_HUB"
  APP_EXECUTABLE="antigravity"
  INSTALL_DIR="${INSTALL_ROOT}/Antigravity"
  BUNDLED_ICON_RELPATH=""   # Hub icon is fetched separately from AUR
fi

# Derived paths — depend on APP_ID so must come after the if/else above
BIN_LINK="${XDG_LOCAL_BIN}/${APP_ID}"
DESKTOP_FILE="${XDG_APPLICATIONS}/${APP_ID}.desktop"
VERSION_FILE="${INSTALL_DIR}/.version"


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3 — HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# Prints a status line. Prefix meanings:
#   [*] = in progress   [+] = success   [!] = warning   [-] = error
log()  { printf '[%s] %s\n' "$1" "$2"; }
info() { log '*' "$1"; }
ok()   { log '+' "$1"; }
warn() { log '!' "$1"; }
err()  { log '-' "$1" >&2; }

# Installs a PNG icon into all configured hicolor size directories.
# Usage: install_icon_to_hicolor <source.png>
install_icon_to_hicolor() {
  local src="$1"
  for size in "${ICON_SIZES[@]}"; do
    local dest="${XDG_ICONS}/${size}/apps/${APP_ID}.png"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  done
}

# Refreshes icon and desktop caches for the current user session.
# Covers GTK icon cache and KDE Plasma's syscoca database.
refresh_de_caches() {
  local hicolor_dir="${XDG_ICONS}"
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$hicolor_dir" 2>/dev/null && \
      ok "GTK icon cache refreshed." || true
  fi
  if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental 2>/dev/null && \
      ok "KDE syscoca6 cache rebuilt." || true
  elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 --noincremental 2>/dev/null && \
      ok "KDE syscoca5 cache rebuilt." || true
  fi
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${XDG_APPLICATIONS}" 2>/dev/null || true
  fi
}

# Downloads a file with a visible progress bar.
# Prefers wget (cleaner rendering), falls back to curl.
download_with_progress() {
  local url="$1" dest="$2"
  if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress --progress=bar:force:noscroll -O "$dest" "$url"
  elif [[ -t 2 ]]; then
    # Redirect curl progress to /dev/tty to prevent cursor bleed on stderr
    curl -fL --progress-bar "$url" -o "$dest" 2>/dev/tty
  else
    curl -fsSL "$url" -o "$dest"
  fi
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4 — UNINSTALL
# ══════════════════════════════════════════════════════════════════════════════

do_uninstall() {
  info "Uninstalling ${APP_NAME}..."

  rm -rf "${INSTALL_DIR}"  || true
  rm -f  "${BIN_LINK}"     || true
  rm -f  "${DESKTOP_FILE}" || true
  for size in "${ICON_SIZES[@]}"; do
    rm -f "${XDG_ICONS}/${size}/apps/${APP_ID}.png" || true
  done

  # Remove legacy v1 system-wide install (Hub only)
  if ! $INSTALL_IDE && [[ -d "$LEGACY_OPT_DIR" ]]; then
    warn "Found legacy v1 install at ${LEGACY_OPT_DIR} — removing (requires sudo)..."
    sudo rm -rf  "$LEGACY_OPT_DIR"
    sudo rm -f   "$LEGACY_BIN" "$LEGACY_DESKTOP_1" "$LEGACY_DESKTOP_2" "$LEGACY_ICON"
  fi

  refresh_de_caches
  ok "Done. ${APP_NAME} removed."
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5 — VERSION DISCOVERY
# Fetches the AUR .SRCINFO and extracts pkgver, tarball URL, and b2sum.
# The tarball URL is read verbatim from source_x86_64 — no reconstruction —
# so this works regardless of which CDN a product uses.
# ══════════════════════════════════════════════════════════════════════════════

fetch_release_info() {
  info "Fetching latest ${APP_NAME} release info from AUR .SRCINFO..."
  local srcinfo
  srcinfo="$(curl -fsSL "${SRCINFO_URL}")"

  PKGVER="$(awk -F' = ' '/^\s*pkgver\s*=/{print $2; exit}' <<< "$srcinfo" \
            | tr -d '[:space:]')"

  TARBALL_URL="$(grep 'source_x86_64' <<< "$srcinfo" \
                 | grep -oP 'https://\S+')"

  EXPECTED_B2SUM="$(grep 'b2sums_x86_64' <<< "$srcinfo" | awk '{print $3}')"

  # Validate parsed values
  if [[ -z "$PKGVER" || -z "$TARBALL_URL" ]]; then
    err "Failed to parse release info from .SRCINFO."
    err "  pkgver    = '${PKGVER}'"
    err "  tarball   = '${TARBALL_URL}'"
    err "Raw .SRCINFO output:"
    echo "$srcinfo" >&2
    exit 1
  fi

  # Enforce 2.x minimum — guard against the AUR package being rolled back
  local major="${PKGVER%%.*}"
  if [[ "$major" -lt 2 ]]; then
    err "AUR reports version ${PKGVER} — expected 2.0 or higher. Aborting."
    exit 1
  fi

  ok "Latest version : ${PKGVER}"
  ok "Tarball URL    : ${TARBALL_URL}"
  ok "b2sum          : ${EXPECTED_B2SUM}"
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6 — DOWNLOAD & VERIFY
# ══════════════════════════════════════════════════════════════════════════════

download_and_verify() {
  info "Downloading ${APP_NAME} tarball..."
  download_with_progress "${TARBALL_URL}" "app.tar.gz"

  if [[ -n "$EXPECTED_B2SUM" ]]; then
    info "Verifying b2sum..."
    echo "${EXPECTED_B2SUM}  app.tar.gz" | b2sum -c -
  else
    warn "No b2sum found in .SRCINFO — skipping integrity check."
  fi
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 7 — EXTRACT
# Extracts into a dedicated subdirectory to safely handle top-level directory
# names that contain spaces (e.g. "Antigravity IDE").
# ══════════════════════════════════════════════════════════════════════════════

extract_tarball() {
  info "Extracting tarball..."
  mkdir extracted
  tar -xzf app.tar.gz -C extracted

  # Glob into an array — the only safe way to capture a path with spaces
  local dirs=( extracted/*/ )
  if [[ ${#dirs[@]} -ne 1 ]]; then
    err "Expected exactly one top-level directory in archive, found:"
    ls -1 extracted/ >&2
    exit 1
  fi

  ACTUAL_DIR="${dirs[0]%/}"   # strip trailing slash added by glob
  ok "Extracted to   : ${ACTUAL_DIR}"

  if [[ ! -f "${ACTUAL_DIR}/${APP_EXECUTABLE}" ]]; then
    err "Executable '${APP_EXECUTABLE}' not found in '${ACTUAL_DIR}'."
    err "Archive top-level contents:"
    ls -1 "${ACTUAL_DIR}" >&2
    exit 1
  fi
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 8 — INSTALL FILES
# Handles legacy cleanup, atomic directory swap, AppArmor, and CLI symlink.
# ══════════════════════════════════════════════════════════════════════════════

install_app() {
  # Remove legacy v1 system-wide install so the shell stops resolving it
  if [[ -d "$LEGACY_OPT_DIR" ]]; then
    warn "Legacy v1 install found at ${LEGACY_OPT_DIR} — removing (requires sudo)..."
    sudo rm -rf  "$LEGACY_OPT_DIR"
    sudo rm -f   "$LEGACY_BIN" "$LEGACY_DESKTOP_1" "$LEGACY_DESKTOP_2" "$LEGACY_ICON"
    ok "Legacy v1 install removed."
  fi

  # Atomic swap: move new dir in, then discard old one
  info "Installing ${APP_NAME} into ${INSTALL_DIR}..."
  mkdir -p "${INSTALL_ROOT}"
  mv "${ACTUAL_DIR}" "${INSTALL_DIR}.new"
  [[ -d "${INSTALL_DIR}" ]] && rm -rf "${INSTALL_DIR}"
  mv "${INSTALL_DIR}.new" "${INSTALL_DIR}"
  echo "${PKGVER}" > "${VERSION_FILE}"

  install_cli_symlink
}

install_cli_symlink() {
  info "Creating CLI symlink at ${BIN_LINK}..."
  mkdir -p "${XDG_LOCAL_BIN}"
  ln -sf "${INSTALL_DIR}/${APP_EXECUTABLE}" "${BIN_LINK}"

  if ! echo ":${PATH}:" | grep -q ":${XDG_LOCAL_BIN}:"; then
    warn "${XDG_LOCAL_BIN} is not in your PATH."
    warn "Add this to ~/.bashrc or ~/.zshrc, then open a new terminal:"
    warn "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
  else
    local resolved
    resolved="$(command -v "${APP_EXECUTABLE}" 2>/dev/null || true)"
    if [[ -n "$resolved" && "$resolved" != "$BIN_LINK" ]]; then
      warn "'${APP_EXECUTABLE}' resolves to '${resolved}', not '${BIN_LINK}'."
      warn "Ensure \${HOME}/.local/bin appears before /usr/local/bin in PATH."
    fi
  fi
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 9 — ICON & DESKTOP INTEGRATION
# Installs the application icon and .desktop launcher, then refreshes caches.
# ══════════════════════════════════════════════════════════════════════════════

install_icon() {
  info "Installing icon..."
  local tmp_icon=""

  if $INSTALL_IDE; then
    # Icon is bundled inside the IDE tarball (confirmed 1024x1024 PNG)
    local src="${INSTALL_DIR}/${BUNDLED_ICON_RELPATH}"
    if [[ -f "$src" ]]; then
      install_icon_to_hicolor "$src"
      ok "IDE icon installed from tarball (hicolor ${ICON_SIZES[*]})."
    else
      warn "Bundled icon not found at: ${src}"
      warn "Launcher will display without an icon until a fix is available."
    fi
  else
    # Hub icon is not in the tarball — fetch from the AUR source tree
    tmp_icon="$(mktemp --suffix=.png)"
    if curl -fsSL "$HUB_ICON_URL" -o "$tmp_icon" && [[ -s "$tmp_icon" ]]; then
      install_icon_to_hicolor "$tmp_icon"
      ok "Hub icon fetched from AUR and installed (hicolor ${ICON_SIZES[*]})."
    else
      warn "Could not fetch Hub icon from AUR. Launcher will display without an icon."
    fi
    rm -f "$tmp_icon"
  fi
}

install_desktop_file() {
  info "Installing .desktop launcher..."
  mkdir -p "${XDG_APPLICATIONS}"

  if $INSTALL_IDE; then
    cat > "${DESKTOP_FILE}" <<DTEOF
[Desktop Entry]
Name=Antigravity IDE
Comment=AI-powered IDE by Google (VS Code fork)
Exec=${INSTALL_DIR}/antigravity-ide %F
Icon=${APP_ID}
Type=Application
StartupNotify=false
StartupWMClass=antigravity-ide
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-antigravity-workspace;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=${INSTALL_DIR}/antigravity-ide --new-window %F
Icon=${APP_ID}
DTEOF
  else
    cat > "${DESKTOP_FILE}" <<DTEOF
[Desktop Entry]
Name=Antigravity
Comment=Agentic development platform by Google
Exec=${INSTALL_DIR}/antigravity %U
Icon=${APP_ID}
Type=Application
StartupNotify=false
StartupWMClass=antigravity
Categories=Development;
MimeType=x-scheme-handler/antigravity;
DTEOF
  fi
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 10 — SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

print_summary() {
  local uninstall_cmd="$0"
  $INSTALL_IDE && uninstall_cmd+=" --ide"
  uninstall_cmd+=" --uninstall"

  printf '\n'
  ok "${APP_NAME} ${PKGVER} installed successfully."
  printf '    Installed at : %s\n'   "${INSTALL_DIR}"
  printf '    CLI symlink  : %s\n'   "${BIN_LINK}"
  printf '    Launcher     : %s\n'   "${DESKTOP_FILE}"
  printf '\n'
  printf '[*] Run:       %s\n'       "$(basename "$BIN_LINK")"
  printf '[*] Update:    re-run %s\n' "$0"
  printf '[*] Uninstall: %s\n'       "$uninstall_cmd"
  printf '\n'
  printf -- '-------------------------------------------------------------------\n'
  printf '  NOTE: If the application icon does not appear correctly in your\n'
  printf '  launcher or taskbar, a full system restart will resolve it.\n'
  printf '  Icon cache rebuilds take effect on next login in some DEs.\n'
  printf -- '-------------------------------------------------------------------\n'
}


# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
  # Uninstall path — exits early
  if $UNINSTALL; then
    do_uninstall
    exit 0
  fi

  # Verify required tools are present before doing any work
  for cmd in curl tar b2sum; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      err "Required command '${cmd}' not found. Install it and retry."
      exit 1
    fi
  done

  # Discover latest version from AUR
  fetch_release_info

  # Skip if already on the latest version
  local installed_ver=""
  [[ -f "${VERSION_FILE}" ]] && installed_ver="$(cat "${VERSION_FILE}")"
  if [[ "$installed_ver" == "$PKGVER" ]]; then
    ok "${APP_NAME} ${PKGVER} is already up to date."
    exit 0
  fi

  # Work in a temp directory — cleaned up automatically on exit
  local workdir
  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT
  cd "$workdir"

  download_and_verify
  extract_tarball
  install_app
  install_icon
  install_desktop_file
  refresh_de_caches
  print_summary
}

main "$@"
