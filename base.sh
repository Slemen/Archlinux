#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# БАЗОВЫЙ СКРИПТ УСТАНОВКИ ARCH LINUX (UEFI + Btrfs + linux-zen / linux-lts)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Ошибка: запустите base.sh от имени root в Live-образе Arch Linux.${NC}"
    exit 1
fi

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  УСТАНОВКА ARCH LINUX (UEFI + BTRFS + ZSTD + LINUX-ZEN & LINUX-LTS)${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Синхронизация системных часов
timedatectl set-ntp true

# 2. Ускорение pacman в Live-среде перед установкой базовых пакетов
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
pacman -Sy --noconfirm archlinux-keyring

# 3. Выбор целевого диска и разметка в cfdisk
echo -e "\n${YELLOW}Доступные накопители:${NC}"
lsblk -d -p -n -l -o NAME,SIZE,MODEL | grep -v "loop"
echo ""
read -rp "Введите путь к целевому диску (например, /dev/nvme0n1 или /dev/sda): " DISK

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Устройство $DISK не найдено!${NC}"
    exit 1
fi

echo -e "${YELLOW}ВНИМАНИЕ! В cfdisk создайте строго 3 раздела по порядку:${NC}"
echo "  1) EFI System (512M - 1G)"
echo "  2) Linux swap (4G - 8G)"
echo "  3) Linux filesystem (всё оставшееся место под Btrfs)"
read -rp "Нажмите Enter для запуска cfdisk $DISK..."
cfdisk "$DISK"

# Определение имён разделов (учитываем префикс p для nvme/mmcblk)
if [[ "$DISK" == *"nvme"* || "$DISK" == *"mmcblk"* ]]; then
    P1="${DISK}p1"
    P2="${DISK}p2"
    P3="${DISK}p3"
else
    P1="${DISK}1"
    P2="${DISK}2"
    P3="${DISK}3"
fi

echo -e "\n${YELLOW}Будут отформатированы следующие разделы:${NC}"
echo "  EFI  : $P1"
echo "  SWAP : $P2"
echo "  BTRFS: $P3"
read -rp "Подтвердите форматирование (введите YES): " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
    echo -e "${RED}Установка отменена пользователем.${NC}"
    exit 1
fi

# 4. Форматирование разделов
mkfs.fat -F32 -n EFI "$P1"
mkswap -L swap "$P2"
swapon "$P2"
mkfs.btrfs -f -L ArchLinux "$P3"

# 5. Создание субтомов Btrfs
mount "$P3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt

# 6. Монтирование субтомов со сжатием zstd:3
BTRFS_OPTS="noatime,compress=zstd:3,space_cache=v2,discard=async"
mount -o "${BTRFS_OPTS},subvol=@" "$P3" /mnt
mkdir -p /mnt/{home,.snapshots,var/log,boot/efi}
mount -o "${BTRFS_OPTS},subvol=@home" "$P3" /mnt/home
mount -o "${BTRFS_OPTS},subvol=@snapshots" "$P3" /mnt/.snapshots
mount -o "${BTRFS_OPTS},subvol=@var_log" "$P3" /mnt/var/log
mount "$P1" /mnt/boot/efi

# 7. Установка базовой системы, связки ядер linux-zen + linux-lts с заголовками и прошивок
echo -e "\n${YELLOW}Установка базовой системы и ядер (linux-zen + linux-lts)...${NC}"
pacstrap -K /mnt \
    base base-devel \
    linux-zen linux-zen-headers \
    linux-lts linux-lts-headers \
    linux-firmware \
    intel-ucode \
    btrfs-progs \
    networkmanager \
    nano vim git curl wget

# 8. Генерация fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 9. Скачивание и автоматический запуск chroot.sh
echo -e "\n${YELLOW}Скачивание chroot.sh и вход в установленную систему...${NC}"
curl -fsSL "https://raw.githubusercontent.com/Slemen/Archlinux/master/chroot.sh" -o /mnt/root/chroot.sh
chmod +x /mnt/root/chroot.sh
arch-chroot /mnt /root/chroot.sh

# 10. Очистка, размонтирование и запрос перезагрузки
rm -f /mnt/root/chroot.sh
echo -e "\n${YELLOW}Размонтирование разделов...${NC}"
swapoff -a || true
umount -R /mnt

echo -e "${GREEN}======================================================================${NC}"
echo -e "${GREEN}Базовая установка Arch Linux и настройка KDE Plasma 6 завершены!${NC}"
echo -e "${GREEN}======================================================================${NC}"
read -rp "Перезагрузить систему прямо сейчас? [Y/n]: " REBOOT_ANS
if [[ "${REBOOT_ANS:-Y}" =~ ^[Yy]$ ]]; then
    reboot
fi
