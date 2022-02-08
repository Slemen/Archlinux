#!/bin/bash
echo 'скрипт второй настройки системы в chroot '
pacman -Syyu --noconfirm
clear

read -p "Введите имя компьютера: " hostname
echo "Используйте в имени только буквы латинского алфавита "
read -p "Введите имя пользователя: " username

echo $hostname > /etc/hostname

echo "Настройка localtime "
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc
echo "Часовой пояс установлен "

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_UA.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo 'LANG=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_ADDRESS=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_IDENTIFICATION=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_MEASUREMENT=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_MONETARY=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_NAME=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_NUMERIC=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_PAPER=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_TELEPHONE=ru_UA.UTF-8' >> /etc/locale.conf
echo 'LC_TIME=ru_UA.UTF-8' >> /etc/locale.conf

echo "KEYMAP=ru" >> /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
clear

echo "Укажите пароль для ROOT "
passwd

groupadd $username
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

EDITOR=nano visudo
clear

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

pacman -Sy xorg-server xorg-xrandr --noconfirm
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

pacman -Sy plasma kde-system-meta plasma-wayland-session kio-extras konsole yakuake htop dkms --noconfirm

pacman -S alsa-utils ark aspell aspell-en aspell-ru audacious rsync duf kio-gdrive --noconfirm

pacman -S dolphin-plugins filelight meld firefox firefox-i18n-ru fish fzf gvfs gvfs-mtp ntfs-3g --noconfirm

pacman -S git kcalc gwenview haveged highlight kfind lib32-alsa-plugins kdeconnect sshfs --noconfirm

pacman -S lib32-freetype2 lib32-glu lib32-libcurl-gnutls lib32-libpulse lib32-libxft lib32-libxinerama --noconfirm

pacman -S lib32-libxrandr lib32-openal lib32-openssl-1.0 lib32-sdl2_mixer nano-syntax-highlighting --noconfirm

pacman -S p7zip pcmanfm pkgfile kwalletmanager xdg-desktop-portal bash-language-server --noconfirm

pacman -S python-pip python-virtualenv python-lsp-server qbittorrent --noconfirm

pacman -S smplayer smplayer-themes kate spectacle starship telegram-desktop unrar yt-dlp expac --noconfirm

pacman -S terminus-font ttf-arphic-ukai ttf-arphic-uming ttf-caladea ttf-carlito ttf-croscore ttf-dejavu ttf-liberation ttf-sazanami noto-fonts-emoji --noconfirm
clear

echo "Добавление репозитория Archlinuxcn "
echo '[archlinuxcn]' >> /etc/pacman.conf
echo 'Server = http://repo.archlinuxcn.org/$arch' >> /etc/pacman.conf
nano /etc/pacman.conf
clear
pacman -Sy archlinuxcn-keyring --noconfirm
clear

echo "Установка дополнительных программ из AUR "
pacman -S pamac-aur downgrade yay timeshift ventoy-bin --noconfirm
clear

pacman -S bluez-utils pulseaudio-bluetooth --noconfirm
systemctl enable bluetooth.service
clear

echo "Установка драйверов "
pacman -S libva-utils libva-intel-driver vulkan-intel lib32-libva lib32-libva-intel-driver lib32-vulkan-intel libvdpau-va-gl opencl-icd-loader lib32-opencl-icd-loader --noconfirm
clear

pacman -Rns discover plasma-thunderbolt bolt plasma-firewall --noconfirm

pacman -S xorg-xinit --noconfirm
cp /etc/X11/xinit/xinitrc /home/$username/.xinitrc
chown $username:users /home/$username/.xinitrc
chmod +x /home/$username/.xinitrc
echo "exec startplasma-x11 " >> /home/$username/.xinitrc
echo ' [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx ' >> /etc/profile
clear

echo "Установка sddm "
pacman -S sddm sddm-kcm --noconfirm
systemctl enable sddm.service -f
clear

pacman -Sy networkmanager networkmanager-openvpn network-manager-applet usb_modeswitch --noconfirm
systemctl enable NetworkManager.service
systemctl enable ModemManager.service
clear

pacman -S tlp tlp-rdw --noconfirm
systemctl enable tlp.service
systemctl enable NetworkManager-dispatcher.service
systemctl mask systemd-rfkill.service
systemctl mask systemd-rfkill.socket
clear
echo ""
echo "Plasma KDE и дополнительные программы успешно установлены"

chsh -s /bin/fish
chsh -s /bin/fish $username
clear

echo '# /dev/sdb1 LABEL=Files
UUID=bc945ea8-3280-49c3-9537-e54f8f8729ee       /files          ext4            defaults,noatime,data=ordered 0 0' >> /etc/fstab

echo "Данный этап может исключить возможные ошибки при первом запуске системы,
фаил откроется через редактор !nano!"
echo ""
echo "Просмотрим/отредактируем /etc/fstab ? "
while
    echo ""
    read -n1 -p  "1 - да, 0 - нет: " vm_fstab # sends right after the keypress
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

echo "Установка завершена, не забудте извлечь USB-накопитель... "
exit
