#!/bin/bash

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

pacman -Sy --noconfirm
echo ""
lsblk -f
##############################
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
  read -p "Укажите ROOT раздел(sda/sdb 1.2.3.4 (sda5 например)):" root
echo ""
mkfs.btrfs -f /dev/$root -L Root
mount /dev/$root /mnt
btrfs sub cr /mnt/@
umount /dev/$root
mount -o rw,noatime,compress=zstd,discard=async,autodefrag,space_cache=v2,subvol=@ /dev/$root /mnt
mkdir -p /mnt/home
################  home     ############################################################
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

   #read -p "Укажите ROOT раздел(sda/sdb 1.2.3.4 (sda5 например)):" root
   #mount -o rw,noatime,compress=zstd,discard=async,autodefrag,space_cache=v2,subvol=@ /dev/$root /mnt
   #mkdir -p /mnt/home

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
########## boot ########
 clear
 lsblk -f
  echo ""
echo 'форматируем BOOT?'
while
    read -n1 -p  "
    1 - да

    0 - нет: " boots # sends right after the keypress
    echo ''
    [[ "$boots" =~ [^10] ]]
do
    :
done
 if [[ $boots == 1 ]]; then
  read -p "Укажите BOOT раздел(sda/sdb 1.2.3.4 (sda7 например)):" bootd
  mkfs.vfat -F32 /dev/$bootd
  mkdir -p /mnt/boot/efi
  mount /dev/$bootd /mnt/boot/efi
  elif [[ $boots == 0 ]]; then
 read -p "Укажите BOOT раздел(sda/sdb 1.2.3.4 (sda7 например)):" bootd
 mkdir /mnt/boot/efi
mount /dev/$bootd /mnt/boot/efi
fi
############ swap ####################################################
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
###################  раздел  ###############################################################
