#!/bin/bash

echo "Установка раскладки клавиатуры"
loadkeys ru
setfont cyr-sun16
clear

echo " Синхронизация системных часов"
timedatectl set-ntp true
clear

echo''
echo " Начнём установку ?"
while
    read -n1 -p  "
 1 - да
 0 - нет: " hello # sends right after the keypress
    echo ''
    [[ "$hello" =~ [^10] ]]
do
    :
done
 if [[ $hello == 1 ]]; then
  clear
  echo " Добро пожаловать в установку ArchLinux режим UEFI"
  elif [[ $hello == 0 ]]; then
   exit
fi

echo " Разметка дисков"
cfdisk /dev/sda --zero
clear

echo " Создание файловых систем"
mkfs.vfat -F32 /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mkfs.btrfs -f -L Root /dev/sda3

echo " Монтирование разделов и подобтомов"
mount /dev/sda3 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt

echo " Монтирование разделов"
mount -o rw,noatime,compress-force=zstd,discard=async,autodefrag,space_cache=v2,subvol=@ /dev/sda3 /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o rw,noatime,compress-force=zstd,discard=async,autodefrag,space_cache=v2,subvol=@home /dev/sda3 /mnt/home
mount /dev/sda1 /mnt/boot/efi
clear
lsblk

pacman -Sy --noconfirm
clear

echo " Установка основных пакетов"
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware dhcpcd netctl inetutils wget pacman-contrib nano wpa_supplicant dialog btrfs-progs intel-ucode iucode-tool

echo " Настройка системы"
genfstab -U /mnt >> /mnt/etc/fstab
clear

echo " Первый скрипт установки готов"
arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/Slemen/Archlinux/master/chroot.sh)"
umount -a
reboot
exit
