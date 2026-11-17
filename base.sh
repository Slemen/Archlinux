#!/usr/bin/env bash
set -euo pipefail

loadkeys ru
setfont cyr-sun16
clear

timedatectl set-ntp true

echo "=========================================="
echo "  УСТАНОВКА ARCH LINUX (ЭТАП 1: БАЗА)"
echo "=========================================="
read -rp "Начать установку? (1 - да, 0 - нет): " start_choice
[[ "$start_choice" == "1" ]] || exit 0

clear
lsblk -d -p -o NAME,SIZE,MODEL
echo ""
read -rp "Введите целевой диск (например, /dev/sda или /dev/nvme0n1): " DISK

if [[ ! -b "$DISK" ]]; then
    echo "[ОШИБКА] Диск $DISK не найден!"
    exit 1
fi

if [[ "$DISK" == *"nvme"* || "$DISK" == *"mmcblk"* ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

echo ""
echo "Создайте 3 раздела в cfdisk на диске $DISK:"
echo "  1) EFI System (512M - 1G)"
echo "  2) Linux swap (по объёму ОЗУ)"
echo "  3) Linux filesystem (всё остальное место под Btrfs)"
read -rp "Нажмите Enter для запуска cfdisk..."
cfdisk "$DISK"
clear

P1="${PART_PREFIX}1"
P2="${PART_PREFIX}2"
P3="${PART_PREFIX}3"

if [[ ! -b "$P1" || ! -b "$P2" || ! -b "$P3" ]]; then
    echo "[ОШИБКА] Не найдены все 3 раздела ($P1, $P2, $P3)!"
    exit 1
fi

echo "Форматирование разделов..."
mkfs.vfat -F32 -n EFI "$P1"
mkswap -L swap "$P2"
swapon "$P2"
mkfs.btrfs -f -L Root "$P3"

mount "$P3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

BTRFS_OPTS="rw,noatime,compress=zstd:3,discard=async,space_cache=v2"
mount -o "${BTRFS_OPTS},subvol=@" "$P3" /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o "${BTRFS_OPTS},subvol=@home" "$P3" /mnt/home
mount "$P1" /mnt/boot/efi

clear
lsblk -f
echo ""

read -rp "Какое ядро установить? (1 - linux-zen + Wi-Fi, 2 - стандартное linux): " kernel_choice
if [[ "$kernel_choice" == "1" ]]; then
    KERNEL_PKGS="linux-zen linux-zen-headers iwd wpa_supplicant"
else
    KERNEL_PKGS="linux linux-headers"
fi

pacman -Sy --noconfirm archlinux-keyring
pacstrap -K /mnt base base-devel $KERNEL_PKGS linux-firmware \
    networkmanager inetutils wget curl git nano vim \
    btrfs-progs intel-ucode iucode-tool pacman-contrib

genfstab -U /mnt >> /mnt/etc/fstab

echo ""
echo "Загрузка второго скрипта (chroot.sh)..."
curl -fsSL https://githubusercontent.com -o /mnt/root/chroot.sh
chmod +x /mnt/root/chroot.sh

read -rp "Запустить настройку внутри chroot автоматически? (1 - да, 2 - войти вручную): " chroot_mode
if [[ "$chroot_mode" == "1" ]]; then
    arch-chroot /mnt /root/chroot.sh
    rm -f /mnt/root/chroot.sh
else
    echo "Для продолжения выполните внутри chroot: /root/chroot.sh"
    arch-chroot /mnt
fi

umount -R /mnt
swapoff -a || true
echo "Первый этап завершён! Извлеките флешку и перезагрузите ПК (reboot)."
EOF
