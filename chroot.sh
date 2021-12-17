#!/bin/bash
echo 'скрипт второй настройки системы в chroot '
timedatectl set-ntp true
pacman -Syyu --noconfirm

read -p "Введите имя компьютера: " hostname
echo "Используйте в имени только буквы латинского алфавита "
read -p "Введите имя пользователя: " username

echo $hostname > /etc/hostname

echo "Настройка localtime "
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
echo "Часовой пояс установлен "

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo "KEYMAP=ru" >> /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
clear

echo ""
echo "Укажите пароль для ROOT "
passwd
useradd -m -g users -G wheel -s /bin/bash $username
echo 'Добавляем пароль для пользователя '$username' '
passwd $username
clear

pacman -Syy --noconfirm
clear
lsblk -f

pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear

nano /etc/sudoers
clear

echo ""
echo "Настроим multilib ?"
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
echo "Настройка мультилиб репозитория пропущена"
elif [[ $i_multilib  == 1 ]]; then
nano /etc/pacman.conf
clear
echo "Multilib репозиторий настроен"
fi
######
pacman -Sy xorg-server xf86-video-intel --noconfirm
clear

echo "Добавление хука автоматической очистки кэша pacman "
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
echo "Хук добавлен "
clear

echo "Установка Plasma KDE и дополнительных программ"

pacman -Sy plasma kde-system-meta kio-extras konsole yakuake htop dkms

pacman -S arch-install-scripts alsa-utils ark aspell aspell-en aspell-ru hspell libvoikko hunspell-ru audacious bat bind rsync duf

pacman -S dolphin-plugins fd filelight findutils meld firefox firefox-i18n-ru fzf gvfs-mtp

pacman -S tig git kcalc gtk-engine-murrine gvfs gwenview haveged highlight kfind lib32-alsa-plugins

pacman -S lib32-freetype2 lib32-glu lib32-libcurl-gnutls lib32-libpulse lib32-libxft lib32-libxinerama

pacman -S lib32-libxrandr lib32-openal lib32-openssl-1.0 lib32-sdl2_mixer nano-syntax-highlighting

pacman -S noto-fonts-emoji p7zip partitionmanager pcmanfm perl-image-exiftool xdg-desktop-portal

pacman -S plasma5-applets-weather-widget python-pip python-virtualenv python-lsp-server qbittorrent

pacman -S kate smplayer smplayer-themes sox spectacle starship telegram-desktop gitui kdeconnect sshfs

pacman -S terminus-font ttf-arphic-ukai ttf-arphic-uming ttf-caladea ttf-carlito ttf-croscore

pacman -S ttf-dejavu ttf-liberation ttf-sazanami unrar xclip xorg-xrandr yt-dlp zim expac

#echo ""
#echo "Добавление репозитория Archlinuxcn"
#echo '[archlinuxcn]' >> /etc/pacman.conf
#echo 'Server = http://repo.archlinuxcn.org/$arch' >> /etc/pacman.conf
#nano /etc/pacman.conf
clear

#pacman -Sy archlinuxcn-keyring --noconfirm
#clear

#pacman -S pamac-aur downgrade yay timeshift ventoy-bin --noconfirm
#clear

pacman -S libva-utils libva-intel-driver vulkan-intel lib32-libva lib32-libva-intel-driver lib32-vulkan-intel libvdpau-va-gl --noconfirm
clear

pacman -S bluez-utils pulseaudio-bluetooth --noconfirm
systemctl enable bluetooth.service
clear

grub-mkfont -s 16 -o /boot/grub/ter-u16b.pf2 /usr/share/fonts/misc/ter-u16b.otb
grub-mkconfig -o /boot/grub/grub.cfg
clear

pacman -Rns discover plasma-thunderbolt bolt plasma-firewall --noconfirm

pacman -S xorg-xinit --noconfirm
cp /etc/X11/xinit/xinitrc /home/$username/.xinitrc
chown $username:users /home/$username/.xinitrc
chmod +x /home/$username/.xinitrc
echo "exec startplasma-x11 " >> /home/$username/.xinitrc
echo ' [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx ' >> /etc/profile
echo ""
pacman -R konqueror --noconfirm
clear
echo "Plasma KDE и дополнительные программы успешно установлены"
echo "Установка sddm"
pacman -S sddm sddm-kcm --noconfirm
systemctl enable sddm.service -f
echo "[General]" >> /etc/sddm.conf
echo "Numlock=on" >> /etc/sddm.conf
clear
echo "Установка sddm  завершена "

pacman -Sy networkmanager networkmanager-openvpn network-manager-applet usb_modeswitch --noconfirm
systemctl enable NetworkManager.service
systemctl enable ModemManager.service
clear
echo ""
echo "Установка  программ закончена"

pacman -S tlp tlp-rdw --noconfirm
systemctl enable tlp.service
systemctl enable NetworkManager-dispatcher.service
systemctl mask systemd-rfkill.service
systemctl mask systemd-rfkill.socket
clear

echo "Замениа терминала на fish"
chsh -s /bin/fish
chsh -s /bin/fish $username
echo "Терминал изменен с bash на fish"

echo '# /dev/sdb1 LABEL=Files
UUID=4ad30ac8-e1fe-4ef8-930c-d743921657d8       /files          ext4            defaults,noatime,data=ordered 0 0' >> /etc/fstab

echo "
 Данный этап может исключить возможные ошибки при первом запуске системы
 Фаил откроется через редактор !nano!"
echo ""
echo "Просмотрим/отредактируем /etc/fstab ?"
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
echo "Установка завершена, не забудте извлечь USB-накопитель..."
exit
