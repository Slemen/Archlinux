#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "  НАСТРОЙКА ARCH LINUX ВНУТРИ CHROOT"
echo "=========================================="

pacman -Syyu --noconfirm

read -rp "Введите имя компьютера (латиницей, например arch-pc): " hostname
read -rp "Введите имя пользователя (латиницей, например slemen): " username

echo "$hostname" > /etc/hostname
cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain ${hostname}
EOF

echo "Настройка часового пояса и локали..."
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
cat << EOF > /etc/vconsole.conf
KEYMAP=ru
FONT=cyr-sun16
EOF

echo ""
echo "Укажите пароль для ROOT:"
passwd

useradd -m -G wheel,audio,video,storage -s /bin/fish "$username"
echo "Укажите пароль для пользователя $username:"
passwd "$username"

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

echo ""
read -rp "Включить репозиторий multilib (32-бит для Steam/Wine)? (1 - да, 0 - нет): " i_multilib
if [[ "$i_multilib" == "1" ]]; then
    sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    pacman -Syy --noconfirm
    echo "Multilib включён."
fi

echo "Установка загрузчика GRUB..."
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

echo "Настройка хука очистки кэша pacman..."
mkdir -p /etc/pacman.d/hooks
cat << 'EOF' > /etc/pacman.d/hooks/cleanup.hook
[Trigger]
Operation = Remove
Operation = Install
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Очистка старого кэша пакетов...
When = PostTransaction
Exec = /usr/bin/paccache -rvk1
EOF

echo ""
echo "Установка KDE Plasma 6 и актуального набора программ..."
pacman -S --noconfirm --needed \
    plasma-meta kde-system-meta sddm kio-extras konsole yakuake \
    htop btop dkms alsa-utils ark aspell aspell-en aspell-ru \
    hunspell hunspell-ru audacious bat bind rsync duf \
    dolphin-plugins fd filelight meld firefox firefox-i18n-ru \
    fish fzf gvfs-mtp tig git kcalc gwenview haveged highlight \
    kfind kdeconnect sshfs nano-syntax-highlighting \
    noto-fonts noto-fonts-cjk noto-fonts-emoji p7zip pcmanfm \
    perl-image-exiftool xdg-desktop-portal xdg-desktop-portal-kde \
    python-pip python-virtualenv qbittorrent kate smplayer \
    sox spectacle starship telegram-desktop gitui terminus-font \
    ttf-caladea ttf-carlito ttf-croscore ttf-dejavu ttf-liberation \
    unrar xclip xorg-xrandr yt-dlp zim expac

pacman -S --noconfirm --needed \
    mesa libva-utils libva-intel-driver intel-media-driver vulkan-intel

if [[ "$i_multilib" == "1" ]]; then
    pacman -S --noconfirm --needed \
        lib32-mesa lib32-vulkan-intel lib32-libva lib32-libva-intel-driver \
        lib32-alsa-plugins lib32-freetype2 lib32-glu lib32-libcurl-gnutls \
        lib32-libpulse lib32-libxft lib32-libxinerama lib32-libxrandr \
        lib32-openal lib32-sdl2_mixer
fi

echo "Установка AUR-помощника yay..."
sudo -u "$username" bash -c '
    cd /tmp
    git clone https://archlinux.org
    cd yay-bin
    makepkg -si --noconfirm
    cd /tmp && rm -rf yay-bin
'

echo "Настройка системных служб..."
pacman -S --noconfirm --needed bluez bluez-utils networkmanager-openvpn network-manager-applet usb_modeswitch tlp tlp-rdw timeshift

systemctl enable sddm.service
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable tlp.service
systemctl enable NetworkManager-dispatcher.service
systemctl mask systemd-rfkill.service systemd-rfkill.socket

mkdir -p /etc/sddm.conf.d
cat << 'EOF' > /etc/sddm.conf.d/numlock.conf
[General]
Numlock=on
EOF

echo ""
echo "=========================================="
echo "  УСТАНОВКА ARCH LINUX ПОЛНОСТЬЮ ЗАВЕРШЕНА!"
echo "=========================================="
EOF
