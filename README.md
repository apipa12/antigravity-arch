# Antigravity Installer (Arch / Garuda / Manjaro)

Unofficial installer for **Google Antigravity** on Arch-based Linux distributions.
Supports both **Antigravity** (the agentic Hub) and **Antigravity IDE** (the VS Code-fork editor).

Неофициальный установщик **Google Antigravity** для дистрибутивов на базе Arch Linux.
Поддерживает **Antigravity** (агентный Hub) и **Antigravity IDE** (редактор на основе VS Code).

***

## ✨ Features / Возможности

- ✅ Fetches the **latest version** of Antigravity Hub or IDE directly from Google's CDN via AUR metadata
- ✅ Verifies integrity via **b2sum checksum**
- ✅ Installs into **`~/Applications/Antigravity`** or **`~/Applications/AntigravityIDE`** (no sudo required)
- ✅ Creates a CLI launcher in **`~/.local/bin`**
- ✅ Installs **.desktop launcher** and application icon into the XDG hicolor theme
- ✅ **Idempotent:** re-running the script updates to the latest version automatically
- ✅ Cleans up legacy v1 `/opt/antigravity` installs automatically

***

## 📂 Repository

GitHub: [https://github.com/apipa12/antigravity-installer](https://github.com/apipa12/antigravity-installer)

***

## 🇬🇧 INSTALL / UPDATE

### 1. Clone the repository

```bash
git clone https://github.com/apipa12/antigravity-installer.git
cd antigravity-installer
```

### 2. Make the installer executable

```bash
chmod +x antigravity-installer.sh
```

### 3. Run the installer

**Antigravity Hub** (pure agentic platform):
```bash
./antigravity-installer.sh
```

**Antigravity IDE** (VS Code-fork with integrated agent):
```bash
./antigravity-installer.sh --ide
```

The script will:

- Fetch the latest version info from AUR `.SRCINFO`
- Download the tarball directly from Google's CDN
- Verify the b2sum checksum
- Install files into `~/Applications/Antigravity` or `~/Applications/AntigravityIDE`
- Create a symlink in `~/.local/bin/`
- Install desktop entry and icon into `~/.local/share/`

### 4. Run Antigravity

```bash
antigravity        # Hub
antigravity-ide    # IDE
```

> If the command is not found, open a new terminal or ensure `~/.local/bin` is in your `PATH`:
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```
> Add this line to `~/.bashrc` or `~/.zshrc` to make it permanent.

### 5. Uninstall

```bash
./antigravity-installer.sh --uninstall        # Uninstall Hub
./antigravity-installer.sh --ide --uninstall  # Uninstall IDE
```

This removes the application directory, CLI symlink, desktop entry, and icons.

> **Icon note:** If the application icon does not appear correctly in your launcher or taskbar after install,
> a full system restart will resolve it. Icon cache rebuilds take effect on next login in some desktop environments.

***

## 🇷🇺 УСТАНОВКА / ОБНОВЛЕНИЕ

### 1. Клонируйте репозиторий

```bash
git clone https://github.com/apipa12/antigravity-installer.git
cd antigravity-installer
```

### 2. Сделайте скрипт исполняемым

```bash
chmod +x antigravity-installer.sh
```

### 3. Запустите установку

**Antigravity Hub** (агентная платформа без редактора):
```bash
./antigravity-installer.sh
```

**Antigravity IDE** (редактор на основе VS Code со встроенным агентом):
```bash
./antigravity-installer.sh --ide
```

Скрипт автоматически:

- Получает информацию о последней версии из AUR `.SRCINFO`
- Загружает архив напрямую с CDN Google
- Проверяет целостность файла по контрольной сумме **b2sum**
- Устанавливает программу в `~/Applications/Antigravity` или `~/Applications/AntigravityIDE`
- Создаёт ярлык в `~/.local/bin/`
- Добавляет ярлык приложения в меню и устанавливает иконку в `~/.local/share/`
- При повторном запуске автоматически обновляет Antigravity до последней версии

### 4. Запуск программы

```bash
antigravity        # Hub
antigravity-ide    # IDE
```

> Если команда не найдена, откройте новый терминал или убедитесь, что `~/.local/bin` добавлен в `PATH`:
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```
> Добавьте эту строку в `~/.bashrc` или `~/.zshrc` для постоянного эффекта.

### 5. Удаление

```bash
./antigravity-installer.sh --uninstall        # Удалить Hub
./antigravity-installer.sh --ide --uninstall  # Удалить IDE
```

Скрипт удалит:

- Установленные файлы из `~/Applications/Antigravity` или `~/Applications/AntigravityIDE`
- Символическую ссылку из `~/.local/bin/`
- Desktop-файл и иконку из `~/.local/share/`

> **Примечание об иконке:** Если иконка приложения не отображается корректно в лаунчере или панели задач
> после установки — перезагрузите систему. Обновление кэша иконок вступает в силу при следующем входе
> в систему в некоторых рабочих окружениях.

***

## 📋 Requirements / Требования

The following tools must be available on your system:

На системе должны быть установлены следующие утилиты:

- `curl`
- `tar`
- `b2sum`
- `wget` *(optional — for cleaner download progress / опционально — для корректного отображения прогресса)*

All are available in Arch `base` / `base-devel`. To install any missing tools:

Все утилиты входят в состав `base` / `base-devel`. Для установки недостающих:

```bash
sudo pacman -S curl tar coreutils wget
```

***

## ⚠️ Disclaimer

- This installer is **unofficial** and is **not affiliated with or endorsed by Google**.
- Use at your own risk. Always review shell scripts before running them.
- The script installs entirely into your home directory and requires `sudo` only to clean up a legacy v1 install under `/opt/antigravity`, if present.

***

## 🛠 Support / Поддержка

If you find a bug or have a feature request:

- Open an issue: [https://github.com/apipa12/antigravity-installer/issues](https://github.com/apipa12/antigravity-installer/issues)

Если вы нашли баг или хотите предложить улучшение:

- Создайте issue: [https://github.com/apipa12/antigravity-installer/issues](https://github.com/apipa12/antigravity-installer/issues)

Contributions, pull requests, and feedback are welcome! 🚀
