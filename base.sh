#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# БАЗОВЫЙ СКРИПТ УСТАНОВКИ ARCH LINUX (UEFI + Btrfs + linux-zen + linux-lts)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  УСТАНОВКА ARCH LINUX (Btrfs + linux-zen + linux-lts + KDE Plasma)${NC}"
echo -e "${CYAN}======================================================================${NC}"

if [[ ! -d /sys/firmware/efi/efivars ]]; then
    echo -e "${RED}Ошибка: Система загружена не в режиме UEFI!${NC}"
    exit 1
fi

timedatectl set-ntp true

echo -e "\n${YELLOW}Доступные диски:${NC}"
lsblk -d -p -n -l -o NAME,SIZE,MODEL | grep -v "loop"

echo ""
read -rp "Введите имя целевого диска (например, /dev/nvme0n1 или /dev/sda): " DISK

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Ошибка: Диск $DISK не найден!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Сейчас откроется cfdisk для разметки $DISK.${NC}"
echo "Создайте строго 3 раздела по порядку:"
echo "  1) EFI System (512M - 1G)"
echo "  2) Linux swap (по объёму ОЗУ, 4G - 8G)"
echo "  3) Linux filesystem (всё оставшееся место под Btrfs)"
read -rp "Нажмите Enter для запуска cfdisk..."
cfdisk "$DISK"

if [[ "$DISK" == *"nvme"* || "$DISK" == *"mmcblk"* ]]; then
    P1="${DISK}p1"
    P2="${DISK}p2"
    P3="${DISK}p3"
else
    P1="${DISK}1"
    P2="${DISK}2"
    P3="${DISK}3"
fi

echo -e "\n${YELLOW}Будут отформатированы разделы:${NC}"
echo "  EFI:   $P1"
echo "  SWAP:  $P2"
echo "  BTRFS: $P3"
read -rp "Продолжить форматирование? Все данные на разделах будут удалены! [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Отмена установки."
    exit 1
fi

echo -e "\n${YELLOW}[1/6] Форматирование разделов...${NC}"
mkfs.fat -F32 -n EFI "$P1"
mkswap -L swap "$P2"
swapon "$P2"
mkfs.btrfs -f -L ArchLinux "$P3"

echo -e "${YELLOW}[2/6] Создание и монтирование субтомов Btrfs (@, @home, @snapshots, @var_log)...${NC}"
mount "$P3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt

BTRFS_OPTS="noatime,compress=zstd:3,space_cache=v2,discard=async"
mount -o "${BTRFS_OPTS},subvol=@" "$P3" /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/log}
mount -o "${BTRFS_OPTS},subvol=@home" "$P3" /mnt/home
mount -o "${BTRFS_OPTS},subvol=@snapshots" "$P3" /mnt/.snapshots
mount -o "${BTRFS_OPTS},subvol=@var_log" "$P3" /mnt/var/log
mount "$P1" /mnt/boot/efi

echo -e "${YELLOW}[3/6] Ускорение pacman в Live-среде...${NC}"
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -Sy --noconfirm archlinux-keyring

echo -e "${YELLOW}[4/6] Установка базовой системы, ядер linux-zen и linux-lts с заголовками...${NC}"
pacstrap -K /mnt base base-devel     linux-zen linux-zen-headers     linux-lts linux-lts-headers     linux-firmware intel-ucode btrfs-progs     networkmanager sudo nano git curl reflector

echo -e "${YELLOW}[5/6] Генерация /etc/fstab...${NC}"
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "${YELLOW}[6/6] Загрузка и запуск chroot.sh...${NC}"
curl -fsSL https://slemen.github.io/Archlinux/chroot.sh -o /mnt/root/chroot.sh
chmod +x /mnt/root/chroot.sh
arch-chroot /mnt /root/chroot.sh

rm -f /mnt/root/chroot.sh
swapoff -a
umount -R /mnt

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Установка Arch Linux полностью завершена!${NC}"
echo -e "${GREEN}======================================================================${NC}"
read -rp "Перезагрузить компьютер сейчас? [Y/n]: " REBOOT_ANS
if [[ ! "$REBOOT_ANS" =~ ^[Nn]$ ]]; then
    reboot
fi
