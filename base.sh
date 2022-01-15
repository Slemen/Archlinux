#!/bin/bash

timedatectl set-ntp true

loadkeys ru
setfont cyr-sun16
clear

echo''
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
###
clear
pacman -Syy --noconfirm

echo "Добро пожаловать в установку ArchLinux режим UEFI "
lsblk -f
echo ""
echo " Выбирайте "1 ", если ранее не производилась разметка диска и у вас нет разделов для ArchLinux "
echo ""
echo 'Нужна разметка диска?'
while
    read -n1 -p  "
    1 - да

    0 - нет: " cfdisk # sends right after the keypress
    echo ''
    [[ "$cfdisk" =~ [^10] ]]
do
    :
done
 if [[ $cfdisk == 1 ]]; then
   clear
 lsblk -f
  echo ""
  read -p "Укажите диск (sda/sdb например sda или sdb) : " cfd
cfdisk /dev/$cfd
echo ""
clear
elif [[ $cfdisk == 0 ]]; then
   echo ""
   clear
   echo 'разметка пропущена.'
fi
#
  clear
  lsblk -f

  echo ""
echo ' добавим и отформатируем BOOT?'
echo " Если производиться установка, и у вас уже имеется бут раздел от предыдущей системы "
echo " тогда вам необходимо его форматировать "1", если у вас бут раздел не вынесен на другой раздел тогда "
echo " этот этап можно пропустить "2" "
while
    read -n1 -p  "
    1 - форматировать и монтировать на отдельный раздел

    2 - пропустить если бут раздела нет : " boots
    echo ''
    [[ "$boots" =~ [^12] ]]
do
    :
done
 if [[ $boots == 1 ]]; then
  read -p "Укажите BOOT раздел(sda/sdb 1.2.3.4 (sda7 например)):" bootd
  mkfs.vfat -F32 /dev/$bootd -L boot/efi
  mkdir /mnt/boot/efi
  mount /dev/$bootd /mnt/boot/efi
  elif [[ $boots == 2 ]]; then
 echo " продолжим дальше "
fi

  echo ""
  read -p "Укажите ROOT раздел(sda/sdb 1.2.3.4 (sda5 например)):" root
echo ""
mkfs.btrfs -f /dev/$root -L Root
mount /dev/$root /mnt

btrfs sub cr /mnt/@
umount /dev/$root
################  home     ############################################################
clear
echo ""
echo " Можно использовать раздел от предыдущей системы( и его не форматировать )
далее в процессе установки можно будет удалить все скрытые файлы и папки в каталоге
пользователя"
echo ""
echo 'Добавим раздел HOME?'
while
    read -n1 -p  "
    1 - да

    0 - нет: " homes # sends right after the keypress
    echo ''
    [[ "$homes" =~ [^10] ]]
do
    :
done
   if [[ $homes == 0 ]]; then
     echo 'пропущено'
  elif [[ $homes == 1 ]]; then
    echo ' Форматируем HOME раздел?'
while
    read -n1 -p  "
    1 - да

    0 - нет: " homeF # sends right after the keypress
    echo ''
    [[ "$homeF" =~ [^10] ]]
do
    :
done
   if [[ $homeF == 1 ]]; then
   echo ""
   lsblk -f
   read -p "Укажите HOME раздел(sda/sdb 1.2.3.4 (sda6 например)):" home
   mkfs.btrfs -f /dev/$home -L Home
   mount /dev/$home /mnt
   btrfs sub cr /mnt/@home
   umount /dev/$home
   lsblk -f

   read -p "Укажите ROOT раздел(sda/sdb 1.2.3.4 (sda5 например)):" root
   mount -o rw,noatime,compress=zstd,discard=async,autodefrag,space_cache=v2,subvol=@ /dev/$root /mnt
   mkdir -p /mnt/home

   read -p "Укажите HOME раздел(sda/sdb 1.2.3.4 (sda6 например)):" homeV
   mount -o rw,noatime,compress=zstd,discard=async,autodefrag,space_cache=v2,subvol=@home /dev/$homeV /mnt/home

   elif [[ $homeF == 0 ]]; then
 lsblk -f
 read -p "Укажите HOME раздел(sda/sdb 1.2.3.4 (sda6 например)):" homeV
 mkdir /mnt/home
 mount -o rw,noatime,compress=zstd,discard=async,autodefrag,space_cache=v2,subvol=@home /dev/$homeV /mnt/home

 lsblk -f

 read -p "Укажите ROOT раздел(sda/sdb 1.2.3.4 (sda5 например)):" root
 mount -o rw,noatime,compress=zstd,discard=async,autodefrag,space_cache=v2,subvol=@ /dev/$root /mnt
fi
fi
############ swap   ####################################################
 clear
 lsblk -f
  echo ""
echo 'добавим swap раздел?'
while
    read -n1 -p  "
    1 - да

    0 - нет: " swap # sends right after the keypress
    echo ''
    [[ "$swap" =~ [^10] ]]
do
    :
done
 if [[ $swap == 1 ]]; then
  read -p "Укажите swap раздел(sda/sdb 1.2.3.4 (sda7 например)):" swaps
  mkswap /dev/$swaps -L swap
  swapon /dev/$swaps
  elif [[ $swap == 0 ]]; then
   echo 'добавление swap раздела пропущено.'
fi
##################################################################################
clear

pacman -Sy --noconfirm
######
clear
echo ""
echo " Если у вас есть wifi модуль и вы сейчас его не используете, но будете использовать потом то для "
echo " исключения ошибок в работе системы рекомендую "1" "
echo ""
echo 'Установка базовой системы, будете ли вы использовать wifi?'
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
 pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware dhcpcd netctl inetutils wget pacman-contrib nano wpa_supplicant dialog btrfs-progs intel-ucode iucode-tool
 genfstab -U /mnt >> /mnt/etc/fstab
 elif [[ $x_pacstrap == 2 ]]; then
  clear
  pacstrap /mnt base dhcpcd linux linux-headers which netctl inetutils pacman-contrib base-devel wget linux-firmware nano btrfs-progs intel-ucode iucode-tool
  genfstab -U /mnt >> /mnt/etc/fstab
  fi
##################################################
clear
echo "Если вы производите установку используя Wifi тогда рекомендую  "1" "
echo ""
echo "если проводной интернет тогда "2" "
echo ""
echo 'wifi или dhcpcd ?'
while
    read -n1 -p  "1 - wifi, 2 - dhcpcd: " int # sends right after the keypress
    echo ''
    [[ "$int" =~ [^12] ]]
do
    :
done
if [[ $int == 1 ]]; then

  curl -LO https://raw.githubusercontent.com/Slemen/Archlinux/master/chroot.sh
  mv chroot.sh /mnt
  chmod +x /mnt/chroot.sh
  echo ""
  echo 'первый этап готов '
  echo 'archLinux chroot'
  echo '1. проверь  интернет для продолжения установки в черуте || 2.команда для запуска ./chroot.sh '
  arch-chroot /mnt
umount -a
reboot
  elif [[ $int == 2 ]]; then
  echo ""
  echo 'первый этап готов '
  echo 'archLinux chroot'
  arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/Slemen/Archlinux/master/chroot.sh)"
umount -a
reboot
fi

elif [[ $menu == 0 ]]; then
exit
fi
