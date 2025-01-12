#!/bin/bash

loadkeys ru
setfont cyr-sun16
clear

timedatectl set-ntp true

echo "Начнём установку? "

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
  echo "Добро пожаловать в установку ArchLinux"
  elif [[ $hello == 0 ]]; then
   exit
fi

cfdisk -z /dev/sda
clear

mkfs.fat -F32 /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mkfs.btrfs -f -L Root /dev/sda3

mount /dev/sda3 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt

mount -o noatime,compress=zstd:2,discard=async,space_cache=v2,subvol=@ /dev/sda3 /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o noatime,compress=zstd:2,discard=async,space_cache=v2,subvol=@home /dev/sda3 /mnt/home
mount /dev/sda1 /mnt/boot/efi
clear
lsblk

pacman -Sy --noconfirm
clear

pacstrap -K /mnt base base-devel linux linux-firmware wget pacman-contrib nano btrfs-progs intel-ucode
genfstab -U /mnt >> /mnt/etc/fstab
clear

echo 'скрипт первой настройки системы готов '
echo 'archLinux chroot'
arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/Slemen/Archlinux/master/chroot.sh)"
umount -a
reboot

elif [[ $menu == 0 ]]; then
exit
fi
