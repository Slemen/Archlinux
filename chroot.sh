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

#pacman -Sy xorg-server xorg-xrandr --noconfirm
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

echo "Установка Plasma KDE и дополнительных программ"

pacman -Sy plasma kde-system-meta kio-extras konsole yakuake htop dkms timeshift --noconfirm

pacman -S alsa-utils ark aspell aspell-en aspell-ru audacious rsync duf kio-gdrive --noconfirm

pacman -S dolphin-plugins filelight meld firefox firefox-i18n-ru fish fzf ntfs-3g --noconfirm

pacman -S git kcalc gwenview haveged highlight kfind lib32-alsa-plugins sof-firmware alsa-ucm-conf sof-tools power-profiles-daemon powerdevil --noconfirm

pacman -S p7zip pcmanfm kwalletmanager xdg-desktop-portal xclip bash-language-server nano-syntax-highlighting --noconfirm

pacman -S smplayer smplayer-themes kate spectacle qbittorrent unrar yt-dlp expac --noconfirm

pacman -S ttf-dejavu ttf-liberation terminus-font noto-fonts-emoji ttf-arphic-ukai ttf-arphic-uming ttf-sazanami --noconfirm
clear

pacman -Rns discover --noconfirm

echo ""
echo "Добавление репозитория Archlinuxcn"
echo '[archlinuxcn]' >> /etc/pacman.conf
echo 'Server = http://repo.archlinuxcn.org/$arch' >> /etc/pacman.conf
nano /etc/pacman.conf
clear

pacman -Sy archlinuxcn-keyring --noconfirm
clear

pacman -S pamac-aur downgrade yay ventoy --noconfirm
clear

pacman -S bluez-utils pulseaudio-bluetooth --noconfirm
systemctl enable bluetooth.service
#clear

pacman -S networkmanager networkmanager-openvpn network-manager-applet --noconfirm
systemctl enable NetworkManager.service
#clear

echo "Установка sddm "
pacman -S sddm 	sddm-kcm --noconfirm
systemctl enable sddm.service -f
#clear

chsh -s /bin/fish
chsh -s /bin/fish $username
clear

echo "Данный этап может исключить возможные ошибки при первом запуске системы,
фаил откроется через редактор !nano!"
echo ""
echo "Просмотрим/отредактируем /etc/fstab ? "
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
