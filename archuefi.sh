#!/bin/bash

loadkeys ru
setfont cyr-sun16

echo 'Синхронизация системных часов'
timedatectl set-ntp true

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

echo 'Создание разделов'
wipefs --all /dev/sda
cfdisk /dev/sda --zero
clear

echo 'Ваша разметка диска'
fdisk -l

echo 'Форматирование дисков'
mkfs.vfat -F32 /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2

mkfs.btrfs -f -L Root /dev/sda3
mount /dev/sda3 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home

echo 'Монтирование дисков'
mount -o rw,noatime,compress-force=zstd,discard=async,autodefrag,space_cache=v2,subvol=@ /dev/sda3 /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o rw,noatime,compress-force=zstd,discard=async,autodefrag,space_cache=v2,subvol=@home /dev/sda3 /mnt/home
mount /dev/sda1 /mnt/boot/efi
clear
lsblk

echo 'Установка основных пакетов'
pacstrap /mnt base base-devel linux linux-headers linux-firmware dhcpcd netctl inetutils wget pacman-contrib nano wpa_supplicant dialog efibootmgr dosfstools btrfs-progs intel-ucode

echo 'Настройка системы'
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/Slemen/Archlinux/master/archuefi2.sh)"
