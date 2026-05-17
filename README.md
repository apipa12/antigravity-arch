# Antigravity Installer (Arch / Garuda / Manjaro)

[![GitHub Issues](https://img.shields.io/github/issues/apipa12/antigravity-arch)](https://github.com/apipa12/antigravity-arch/issues)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#)

Unofficial installer for **Google Antigravity** on Arch-based Linux distributions.
*Неофициальный установщик **Google Antigravity** для дистрибутивов на базе Arch Linux.*

---

## ✨ Features / Возможности

- ✅ Fetches the **latest Antigravity build** directly from Google APT
- ✅ Verifies integrity via **SHA256 checksum**
- ✅ Installs binaries into `/opt/antigravity`
- ✅ Creates a convenient `antigravity` launcher in `/usr/local/bin`
- ✅ Installs **.desktop launcher** and application icon
- ✅ Applies **Chrome-style sandbox** fix for better compatibility
- ✅ **Idempotent:** re-running the installer safely updates Antigravity to the latest version

---

## 🚀 Quick Start / Быстрый старт

### 1. Clone & Run / Клонировать и запустить

```bash
git clone https://github.com/apipa12/antigravity-arch.git
cd antigravity-arch
chmod +x antigravity-installer.sh
./antigravity-installer.sh
```

### 2. Launch / Запуск
```bash
antigravity
```

### 3. Uninstall / Удаление
```bash
./antigravity-installer.sh --uninstall
```

---

## 📋 Requirements / Требования

Ensure the following utilities are installed / Убедитесь, что установлены следующие утилиты: `curl`, `bsdtar`, `sha256sum`, `awk`, `sudo`.

```bash
sudo pacman -S curl libarchive coreutils gawk sudo
```

---

## ℹ️ Details / Подробности

<details>
<summary><strong>🇬🇧 English Details</strong></summary>

**How it works:**
The script automatically finds the latest available version of Antigravity in the Google APT repositories, downloads the `.deb` package, verifies its SHA256 checksum, extracts the contents, and installs them into `/opt/antigravity`. It sets up symlinks and desktop icons for a native feel.

**Uninstall:**
Running with `--uninstall` removes all binaries, symlinks, and desktop entries installed by the script.

</details>

<details>
<summary><strong>🇷🇺 Подробности на русском</strong></summary>

**Как это работает:**
Скрипт автоматически находит последнюю доступную версию Antigravity в репозиториях Google APT, скачивает `.deb` пакет, проверяет его контрольную сумму SHA256, извлекает содержимое и устанавливает в `/opt/antigravity`. Также он настраивает симлинки и иконки рабочего стола для удобного использования.

**Удаление:**
Запуск с флагом `--uninstall` удалит все файлы, символические ссылки и ярлыки, добавленные инсталлером.

</details>

---

## ⚠️ Disclaimer

- This installer is **unofficial** and is **not affiliated with or endorsed by Google**.
- Use at your own risk. Always review shell scripts before running them with elevated privileges.

## 🛠 Support / Поддержка

Found a bug or want to suggest a feature?
Нашли баг или хотите предложить улучшение?

[👉 Open an issue on GitHub](https://github.com/apipa12/antigravity-arch/issues)

Contributions and pull requests are welcome! 🚀
