#!/bin/bash

echo 'Прописываем имя компьютера'
echo $hostname > /etc/hostname
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc

echo 'Добавляем русскую локаль системы'
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 

echo 'Обновим текущую локаль системы'
locale-gen

echo 'Указываем язык системы'
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf

echo 'Вписываем KEYMAP=ru FONT=cyr-sun16'
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

echo 'Создадим загрузочный RAM диск'
mkinitcpio -p linux
clear

echo 'Создаем root пароль'
passwd

echo 'Устанавливаем загрузчик'
pacman -Syy --noconfirm
pacman -S grub --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub

echo 'Обновляем grub.cfg'
grub-mkconfig -o /boot/grub/grub.cfg
clear
