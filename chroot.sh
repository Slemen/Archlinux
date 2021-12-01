#!/bin/bash
echo " Второй скрипт установки системы в arch-chroot"
echo "  Настройка часового пояса"
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc

echo " Добавляем русскую локаль системы и язык"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
echo " Обновим текущую локаль системы"
locale-gen
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo "KEYMAP=ru" >> /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
clear

read -p " Введите имя компьютера: " hostname
echo " Используйте в имени только буквы латинского алфавита"
read -p " Введите имя пользователя: " username
clear

echo " Настройка сети"
echo $hostname > /etc/hostname
echo '127.0.0.1  localhost' >> /etc/hosts
echo '::1        localhost' >> /etc/hosts
echo "127.0.1.1  $hostname.localdomain $hostname" >> /etc/hosts
clear

echo " Создание загрузочного RAM диска"
mkinitcpio -p linux
clear

echo " Укажите пароль для ROOT"
passwd
useradd -m -g users -G wheel -s /bin/bash $username
echo ' Добавляем пароль для пользователя '$username' '
passwd $username

echo " Устанавливаем SUDO"
nano /etc/sudoers
clear

pacman -Syy --noconfirm
clear

echo " Устанавливаем загрузчик UEFI-GRUB"
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub

echo " Обновляем grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg
clear

echo ""
echo " Настроим multilib ?"
while
    read -n1 -p  "
 1 - да
 0 - нет : " i_multilib   # sends right after the keypress
    echo ''
    [[ "$i_multilib" =~ [^10] ]]
do
    :
done
if [[ $i_multilib  == 0 ]]; then
clear
echo " Настройка мультилиб репозитория пропущена"
elif [[ $i_multilib  == 1 ]]; then
nano /etc/pacman.conf
clear
echo " Multilib репозиторий настроен"
fi
pacman -Syy --noconfirm

echo " Ставим иксы и драйвера"
pacman -S xorg-server xf86-video-intel --noconfirm
clear

echo " Добавление хука автоматической очистки кэша pacman"
echo "[Trigger]
Operation = Remove
Operation = Install
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Removing unnecessary cached files…
When = PostTransaction
Exec = /usr/bin/paccache -rvk0" >> /usr/share/libalpm/hooks/cleanup.hook
clear

echo " Установка Plasma KDE и дополнительных программ"

pacman -S plasma kde-system-meta kio-extras konsole yakuake htop dkms --noconfirm

pacman -S alsa-utils ark aspell aspell-en aspell-ru audacious audacious-plugins bat bind --noconfirm

pacman -S firefox firefox-i18n-ru dnsmasq dolphin-plugins fd filelight fzf git meld --noconfirm

pacman -S kcalc fish telegram-desktop gvfs gvfs-mtp gwenview haveged --noconfirm

pacman -S highlight kfind lib32-alsa-plugins lib32-freetype2 lib32-glu lib32-libcurl-gnutls --noconfirm

pacman -S lib32-libpulse lib32-libxft lib32-libxinerama lib32-libxrandr lib32-openal lib32-openssl-1.0 --noconfirm

pacman -S lib32-sdl2_mixer nano-syntax-highlighting neofetch noto-fonts-emoji okular perl-image-exiftool --noconfirm

pacman -S pcmanfm pkgfile p7zip pulseaudio-alsa dosfstools --noconfirm

pacman -S qbittorrent plasma5-applets-weather-widget qt5-xmlpatterns --noconfirm

pacman -S kate smplayer smplayer-themes spectacle terminus-font kdeconnect sshfs --noconfirm

pacman -S ttf-arphic-ukai ttf-arphic-uming ttf-caladea ttf-carlito ttf-croscore ttf-dejavu --noconfirm

pacman -S ttf-liberation ttf-sazanami unrar xclip zim yt-dlp starship --noconfirm

echo "Добавление репозитория Archlinuxcn"
echo '[archlinuxcn]' >> /etc/pacman.conf
echo 'Server = http://repo.archlinuxcn.org/$arch' >> /etc/pacman.conf
nano /etc/pacman.conf
clear
pacman -Sy archlinuxcn-keyring --noconfirm
clear

echo " Установка дополнительных программ из AUR"
pacman -S downgrade yay timeshift ventoy-bin --noconfirm

echo " Установка драйвера intel,vulkan и VA-API"
pacman -S libva libva-utils libva-intel-driver vulkan-intel lib32-libva lib32-libva-intel-driver lib32-vulkan-intel --noconfirm
clear

echo " Диспетчер blutooth устройств"
pacman -S bluez-utils pulseaudio-bluetooth --noconfirm
systemctl enable bluetooth.service
clear

echo " Удаление программ"
pacman -Rns discover plasma-thunderbolt bolt plasma-firewall --noconfirm

grub-mkfont -s 16 -o /boot/grub/ter-u16b.pf2 /usr/share/fonts/misc/ter-u16b.otb
grub-mkconfig -o /boot/grub/grub.cfg
clear

pacman -S xorg-xinit --noconfirm
cp /etc/X11/xinit/xinitrc /home/$username/.xinitrc
chown $username:users /home/$username/.xinitrc
chmod +x /home/$username/.xinitrc
echo "exec startplasma-x11 " >> /home/$username/.xinitrc
echo ' [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx ' >> /etc/profile
echo ""
echo " Plasma KDE и дополнительные программы успешно установлены"

pacman -R konqueror --noconfirm
clear

echo " Установка sddm"
pacman -S sddm sddm-kcm --noconfirm
systemctl enable sddm.service -f
echo "[General]" >> /etc/sddm.conf
echo "..." >> /etc/sddm.conf
echo "Numlock=on" >> /etc/sddm.conf
clear

echo " Установка сетевых утилит"
pacman -S networkmanager networkmanager-openvpn network-manager-applet usb_modeswitch --noconfirm
systemctl enable NetworkManager.service
systemctl enable ModemManager.service
clear

echo " Установка TLP - Оптимизация времени автономной работы ноутбука с Linux"
pacman -S tlp tlp-rdw --noconfirm
systemctl enable tlp.service
systemctl enable NetworkManager-dispatcher.service
systemctl mask systemd-rfkill.service
systemctl mask systemd-rfkill.socket
clear

echo " Оболочка изменена с bash на fish"
chsh -s /bin/fish
chsh -s /bin/fish $username
clear

echo " Монтирование диска sdb1"
echo '# /dev/sdb1 LABEL=Files
UUID=4ad30ac8-e1fe-4ef8-930c-d743921657d8       /files          ext4            defaults,noatime,data=ordered 0 0' >> /etc/fstab
clear

echo "
 Данный этап может исключить возможные ошибки при первом запуске системы
 Фаил откроется через редактор !nano!"
echo ""
echo " Просмотрим/отредактируем /etc/fstab ?"
while
    read -n1 -p  "
 1 - да
 0 - нет: " vm_fstab # sends right after the keypress
    echo ''
    [[ "$vm_fstab" =~ [^10] ]]
do
    :
done
if [[ $vm_fstab == 0 ]]; then
  echo 'этап пропущен'
elif [[ $vm_fstab == 1 ]]; then
nano /etc/fstab
fi
clear

echo ""
echo " Второй скрипт установки готов"
echo " Установка завершена, не забудте извлечь USB-накопитель..."
exit
