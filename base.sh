#!/bin/bash
#'Установка раскладки клавиатуры'
loadkeys ru
setfont cyr-sun16
clear

#'Синхронизация системных часов'
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

#'Разметка диска'
#wipefs --all /dev/sda
cfdisk /dev/sda --zero
clear

#'Форматирование разделов'
mkfs.vfat -F32 /dev/sda1
mkswap -L swap /dev/sda2
#'Включение swap'
swapon /dev/sda2

#'Создание тома и подтомов (субволумов)'
mkfs.btrfs -f -L Root /dev/sda3
mount /dev/sda3 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home

umount -R /mnt

#'Монтирование разделов'
mount -o rw,noatime,compress-force=zstd,discard=async,autodefrag,space_cache=v2,subvol=@ /dev/sda3 /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o rw,noatime,compress-force=zstd,discard=async,autodefrag,space_cache=v2,subvol=@home /dev/sda3 /mnt/home
mount /dev/sda1 /mnt/boot/efi
clear
lsblk
pacman -Sy --noconfirm 
######
clear
echo ""
echo " Если у вас есть wifi модуль и вы сейчас его не используете, то для"
echo " исключения ошибок в работе системы рекомендую "1" "
echo ""
echo ' Установка основных пакетов, будете ли вы использовать wifi ?'
while
    read -n1 -p  "
 1 - да
 2 - нет: " x_pacstrap  # sends right after the keypress
    echo ''
    [[ "$x_pacstrap" =~ [^12] ]]
do
    :
done
 if [[ $x_pacstrap == 1 ]]; then
  clear
  pacstrap /mnt base base-devel linux linux-headers linux-firmware dhcpcd netctl inetutils wget pacman-contrib nano wpa_supplicant dialog efibootmgr dosfstools btrfs-progs intel-ucode
  genfstab -U /mnt >> /mnt/etc/fstab
elif [[ $x_pacstrap == 2 ]]; then
  clear
  pacstrap /mnt base base-devel linux linux-headers linux-firmware dhcpcd netctl inetutils wget pacman-contrib nano efibootmgr dosfstools btrfs-progs intel-ucode
  genfstab -U /mnt >> /mnt/etc/fstab
fi
 clear

echo " Если вы производите установку используя Wifi тогда рекомендую  "1" "
echo " Если проводной интернет тогда "2" "
echo ""
echo ' wifi или dhcpcd ?'
while
    read -n1 -p  "
 1 - wifi 
 2 - dhcpcd: " int # sends right after the keypress
    echo ''
    [[ "$int" =~ [^12] ]]
do
    :
done
if [[ $int == 1 ]]; then

curl -LO https://raw.githubusercontent.com/Slemen/Archlinux/master/chroot.sh
  mv chroot.sh /mnt
  chmod +x /mnt/chroot.sh

  echo ' Первый этап готов'
  echo ' Arch-chroot'
  echo ' 1. проверь  интернет для продолжения установки в черуте || 2.команда для запуска ./chroot.sh '
  arch-chroot /mnt
umount -a
reboot
  elif [[ $int == 2 ]]; then
  echo ' Первый этап готов'
  echo ' Arch-chroot'
  arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/Slemen/Archlinux/master/chroot.sh)"
  umount -a
reboot
fi
elif [[ $menu == 0 ]]; then
exit
fi
