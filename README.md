# archlinux-script-install

Набор автоматизированных скриптов для чистой установки и настройки **Arch Linux (UEFI + Btrfs + KDE Plasma 6 + Wayland)** под современные ноутбуки (на примере **Acer Nitro V 15**).

> **ВНИМАНИЕ (Дисклеймер):** Скрипты созданы автором под собственные нужды и конкретное оборудование (Acer Nitro V 15). Автор не несёт ответственности за последствия их использования на других системах.

---

## Состав репозитория (ветка `master`)

| Файл | Назначение | Где запускается |
| :--- | :--- | :--- |
| **`base.sh`** | Разметка диска (`cfdisk`), субтома Btrfs (`@`, `@home`, `@snapshots`, `@var_log`), установка ядра **`linux-zen`** + резервного **`linux-lts`** (с заголовками `*-headers`), автозапуск `chroot.sh`, авторазмонтирование и запрос перезагрузки. | Live-образ Arch Linux (`root`) |
| **`chroot.sh`** | Настройка локалей и времени, ускорение `pacman`/`makepkg`, установка **KDE Plasma 6**, ZRAM (`zstd`), твиков ядра `sysctl` (CachyOS), `earlyoom`, блокировка `iTCO_wdt`, профиль Konsole **`Newbl1nk`**, **`Fish`**, **`Starship`**, **`.nanorc`**, `yay-bin` и загрузчика GRUB. | Запускается автоматически из `base.sh` |
| **`menu.sh`** | Интерактивное меню пост-установки: позволяет в одном окне выбрать установку драйверов NVIDIA, программ, диагностику или перезагрузку. | Установленная система (пользователь) |
| **`nvidia.sh`** | Установка драйверов **`nvidia-dkms`**, **`nvidia-prime`** (`prime-run`), Vulkan, VA-API, настройка Early KMS в `mkinitcpio`, параметров Wayland в GRUB, служб сна и `nvidia.hook`. | Установленная система (пользователь) |
| **`apps.sh`** | Установка игровых и повседневных программ (`steam`, `gamemode`, `libreoffice-fresh-ru`, `vlc`, `qbittorrent`, `yt-dlp`, `ffmpeg`) и настройка игрового буфера звука PipeWire. | Установленная система (пользователь) |
| **`verify_arch.sh`** | Автоматическая диагностика всех 10 ключевых узлов системы после установки и перезагрузки. | Установленная система (пользователь) |

---

## Готовые команды для запуска в терминале

### 1. Базовая установка и KDE Plasma 6 (из Live-образа Arch Linux)
Подключитесь к интернету (через `iwctl` или кабель) и выполните:
```bash
curl -fsSL https://slemen.github.io/Archlinux/base.sh -o base.sh && chmod +x base.sh && ./base.sh
```
*(Скрипт `chroot.sh` скачается и запустится изнутри `base.sh` автоматически, а в конце выполнит размонтирование и предложит перезагрузить ПК).*

#### Памятка по разметке диска в `cfdisk` (строго 3 раздела по порядку):

| Номер раздела | Тип раздела (`Type`) | Рекомендуемый размер | Назначение |
| :---: | :--- | :--- | :--- |
| **1** | `EFI System` | `512M` – `1G` | Загрузочный раздел `/boot/efi` (FAT32) |
| **2** | `Linux swap` | `4G` – `8G` | Дисковый swap (работает в паре со сжатым ZRAM) |
| **3** | `Linux filesystem` | Всё оставшееся место | Основной раздел **Btrfs** (сжатие `zstd:3`) |

---

### 2. Интерактивное меню пост-установки (рекомендуется после перезагрузки в KDE)
После входа в KDE Plasma откройте Konsole и запустите единое меню — оно само скачает и запустит нужные скрипты по вашему выбору:
```bash
curl -fsSL https://slemen.github.io/Archlinux/menu.sh -o ~/menu.sh && chmod +x ~/menu.sh && ~/menu.sh
```

---

### 3. Отдельный запуск скриптов (при необходимости)

* **Установка драйверов NVIDIA:**
  ```bash
  curl -fsSL https://slemen.github.io/Archlinux/nvidia.sh -o ~/nvidia.sh && chmod +x ~/nvidia.sh && ~/nvidia.sh
  ```
* **Установка программ (Steam, LibreOffice, медиа, PipeWire):**
  ```bash
  curl -fsSL https://slemen.github.io/Archlinux/apps.sh -o ~/apps.sh && chmod +x ~/apps.sh && ~/apps.sh
  ```
* **Проверка всех настроек системы:**
  ```bash
  curl -fsSL https://slemen.github.io/Archlinux/verify_arch.sh -o ~/verify_arch.sh && chmod +x ~/verify_arch.sh && ~/verify_arch.sh
  ```

---

## Полезная шпаргалка после установки

* **Запуск приложений и игр на дискретной видеокарте NVIDIA (`nvidia-prime`):**
  ```bash
  prime-run glxinfo | grep "OpenGL renderer"
  ```
* **Параметры запуска игр в Steam (NVIDIA + GameMode):**
  ```bash
  prime-run gamemoderun %command%
  ```
* **Переключение между ядрами при загрузке:** В меню **GRUB** по умолчанию загружается игровое ядро **`linux-zen`**, а в подменю *Advanced options for Arch Linux* всегда доступно резервное ядро **`linux-lts`**.
