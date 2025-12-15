#!/usr/bin/env bash
set -euo pipefail

# Antigravity installer script for Arch-based distributions
# This script automatically fetches the latest version of Google Antigravity from its
# official APT repository, verifies it with SHA256, extracts it, and installs it in /opt/antigravity.
#
# Usage:
#   ./antigravity-installer.sh        # install or update to latest
#   ./antigravity-installer.sh --uninstall

APT_BASE="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"
PKG_INDEX_URL="${APT_BASE}/dists/antigravity-debian/main/binary-amd64/Packages"

APP_DIR="/opt/antigravity"
BIN_LINK="/usr/local/bin/antigravity"
DESKTOP1="/usr/share/applications/antigravity.desktop"
DESKTOP2="/usr/share/applications/antigravity-url-handler.desktop"
ICON_PATH="/usr/share/pixmaps/antigravity.png"

if [[ "${1-}" == "--uninstall" ]]; then
  echo "[*] Uninstalling Antigravity..."
  sudo rm -rf "$APP_DIR" || true
  sudo rm -f "$BIN_LINK" || true
  sudo rm -f "$DESKTOP1" "$DESKTOP2" || true
  sudo rm -f "$ICON_PATH" || true
  echo "[+] Done. Antigravity removed."
  exit 0
fi

# requirements check
for cmd in curl bsdtar sha256sum awk; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[-] Required command '$cmd' not found. Install it and retry: $cmd" >&2
    exit 1
  fi
done

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

echo "[*] Fetching APT Packages index..."
curl -fsSL "$PKG_INDEX_URL" -o Packages

echo "[*] Parsing latest antigravity entry..."
read -r DEBVER DEBFILENAME DEBSHA256 <<< "$(
  awk '
    /^Package: antigravity$/ {
      pkg="antigravity";
      ver=""; file=""; sha="";
      next;
    }
    pkg=="antigravity" && /^Version:/ { ver=$2 }
    pkg=="antigravity" && /^Filename:/ { file=$2 }
    pkg=="antigravity" && /^SHA256:/ { sha=$2 }
    
    NF==0 && pkg=="antigravity" && ver!="" && file!="" && sha!="" {
      print ver, file, sha;
      pkg="";
    }
    
    END {
      if (pkg=="antigravity" && ver!="" && file!="" && sha!="")
        print ver, file, sha;
    }
  ' Packages | sort -V | tail -n 1
)"

if [[ -z "${DEBVER:-}" || -z "${DEBFILENAME:-}" || -z "${DEBSHA256:-}" ]]; then
  echo "[-] Failed to parse antigravity package info from Packages index" >&2
  exit 1
fi

echo "[+] Latest version:  $DEBVER"
echo "[+] Filename:        $DEBFILENAME"
echo "[+] SHA256:          $DEBSHA256"

DEB_URL="${APT_BASE}/${DEBFILENAME}"
DEB_FILE="antigravity.deb"

echo "[*] Downloading DEB from:"
echo "    $DEB_URL"
curl -fsSL "$DEB_URL" -o "$DEB_FILE"

echo "[*] Verifying SHA256..."
echo "${DEBSHA256}  ${DEB_FILE}" | sha256sum -c -

echo "[*] Extracting DEB..."
bsdtar -xf "$DEB_FILE"
bsdtar -xf data.tar.xz

if [[ ! -d usr/share/antigravity ]]; then
  echo "[-] Unexpected DEB structure: usr/share/antigravity not found." >&2
  exit 1
fi

echo "[*] Installing into ${APP_DIR} (requires sudo)..."
sudo rm -rf "$APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo cp -r usr/share/antigravity/* "$APP_DIR/"

# sandbox (Chrome / VS Code style)
if [[ -f "$APP_DIR/chrome-sandbox" ]]; then
  sudo chown root:root "$APP_DIR/chrome-sandbox" || true
  sudo chmod 4755 "$APP_DIR/chrome-sandbox" || true
fi

echo "[*] Creating binary symlink ${BIN_LINK}..."
sudo mkdir -p "$(dirname "$BIN_LINK")"
sudo ln -sf "$APP_DIR/antigravity" "$BIN_LINK"

echo "[*] Installing .desktop files..."
if [[ -f usr/share/applications/antigravity.desktop ]]; then
  tmp1="$(mktemp)"
  sed 's|^Exec=.*|Exec=/opt/antigravity/antigravity %U|g' \
    usr/share/applications/antigravity.desktop > "$tmp1"
  sudo install -Dm644 "$tmp1" "$DESKTOP1"
fi

if [[ -f usr/share/applications/antigravity-url-handler.desktop ]]; then
  tmp2="$(mktemp)"
  sed 's|^Exec=.*|Exec=/opt/antigravity/antigravity %U|g' \
    usr/share/applications/antigravity-url-handler.desktop > "$tmp2"
  sudo install -Dm644 "$tmp2" "$DESKTOP2"
fi

echo "[*] Installing icon..."
if [[ -f usr/share/pixmaps/antigravity.png ]]; then
  sudo install -Dm644 usr/share/pixmaps/antigravity.png "$ICON_PATH"
fi

echo
echo "[+] Antigravity ${DEBVER} installed successfully."
echo "[*] Run:  antigravity"
echo "[*] To uninstall:  $0 --uninstall"
