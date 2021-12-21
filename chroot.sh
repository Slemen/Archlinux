#!/bin/bash
echo 'скрипт второй настройки системы в chroot '
pacman -Syyu --noconfirm

echo ""
read -p "Введите имя компьютера: " hostname
echo ""
echo " Используйте в имени только буквы латинского алфавита "
echo ""
read -p "Введите имя пользователя: " username

echo $hostname > /etc/hostname
#####################################
echo "Настройка localtime "
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc
echo "Часовой пояс установлен "
#####################################
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo "KEYMAP=ru" >> /etc/vconsole.conf
echo "FONT=ter-u16b" >> /etc/vconsole.conf
echo ""
echo "Укажите пароль для ROOT "
passwd

echo ""
groupadd $username
useradd -m -g $username -G wheel -s /bin/bash $username
echo ""
echo 'Добавляем пароль для пользователя '$username' '
echo ""
passwd $username

pacman -Syy --noconfirm
clear
lsblk -f
###########################################################################
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
#clear
##########
nano /etc/sudoers
clear
##########
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
#clear

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
echo " "
echo "Установка KDE и набора программ "
echo " "

echo " "

pacman -Sy plasma kde-system-meta kio-extras konsole yakuake htop dkms --noconfirm

#pacman -S arch-install-scripts alsa-utils ark aspell aspell-en aspell-ru hspell libvoikko hunspell-ru audacious bat bind rsync duf --noconfirm

#pacman -S dolphin-plugins fd filelight meld firefox firefox-i18n-ru fish fzf gvfs-mtp --noconfirm

#pacman -S tig git kcalc gwenview haveged highlight kfind lib32-alsa-plugins kdeconnect sshfs --noconfirm

#pacman -S lib32-freetype2 lib32-glu lib32-libcurl-gnutls lib32-libpulse lib32-libxft lib32-libxinerama --noconfirm

#pacman -S lib32-libxrandr lib32-openal lib32-openssl-1.0 lib32-sdl2_mixer nano-syntax-highlighting --noconfirm

#pacman -S noto-fonts-emoji p7zip pcmanfm perl-image-exiftool xdg-desktop-portal --noconfirm

#pacman -S plasma5-applets-weather-widget python-pip python-virtualenv python-lsp-server bash-language-server qbittorrent --noconfirm

#pacman -S kate smplayer smplayer-themes sox spectacle starship telegram-desktop gitui --noconfirm

#pacman -S terminus-font ttf-arphic-ukai ttf-arphic-uming ttf-caladea ttf-carlito ttf-croscore --noconfirm

#pacman -S ttf-dejavu ttf-liberation ttf-sazanami unrar xclip xorg-xrandr yt-dlp zim expac --noconfirm
#clear

pacman -S libva-utils libva-intel-driver vulkan-intel lib32-libva lib32-libva-intel-driver lib32-vulkan-intel libvdpau-va-gl --noconfirm
clear

pacman -Rns discover --noconfirm

echo ""
echo "Добавление репозитория Archlinuxcn"
echo '[archlinuxcn]' >> /etc/pacman.conf
echo 'Server = http://repo.archlinuxcn.org/$arch' >> /etc/pacman.conf
nano /etc/pacman.conf
clear

pacman -Sy archlinuxcn-keyring --noconfirm
#clear

pacman -S pamac-aur downgrade yay timeshift ventoy-bin
#clear

grub-mkfont -s 16 -o /boot/grub/ter-u16b.pf2 /usr/share/fonts/misc/ter-u16b.otb
grub-mkconfig -o /boot/grub/grub.cfg
clear

pacman -S bluez-utils pulseaudio-bluetooth
systemctl enable bluetooth.service
#clear

pacman -S xorg-xinit
cp /etc/X11/xinit/xinitrc /home/$username/.xinitrc
chown $username:$username /home/$username/.xinitrc
chmod +x /home/$username/.xinitrc
echo "exec startplasma-x11 " >> /home/$username/.xinitrc
echo ' [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx ' >> /etc/profile
echo ""
#pacman -R konqueror --noconfirm
clear

#echo "Установка sddm "
#pacman -S sddm sddm-kcm --noconfirm
systemctl enable sddm.service -f
echo "[General]" >> /etc/sddm.conf
#echo "..." >> /etc/sddm.conf
echo "Numlock=on" >> /etc/sddm.conf
clear
#echo " установка sddm  завершена "

pacman -Sy networkmanager-openvpn network-manager-applet usb_modeswitch
systemctl enable NetworkManager.service
systemctl enable ModemManager.service
#clear
#networkmanager
pacman -S tlp tlp-rdw
systemctl enable tlp.service
systemctl enable NetworkManager-dispatcher.service
systemctl mask systemd-rfkill.service
systemctl mask systemd-rfkill.socket
#clear
echo "Plasma KDE успешно установлена"
chsh -s /bin/fish
chsh -s /bin/fish $username
clear

echo '# /dev/sdb1 LABEL=Files
UUID=4ad30ac8-e1fe-4ef8-930c-d743921657d8       /files          ext4            defaults,noatime,data=ordered 0 0' >> /etc/fstab
clear

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
