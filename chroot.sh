#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# СКРИПТ НАСТРОЙКИ ВНУТРИ ARCH-CHROOT (KDE Plasma 6, ZRAM, CachyOS tweaks, Fish)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  НАСТРОЙКА СИСТЕМЫ ВНУТРИ CHROOT (KDE PLASMA 6 + OPTIMIZATIONS)${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Часовой пояс и локализация
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
cat << 'EOF' > /etc/vconsole.conf
KEYMAP=ru
FONT=cyr-sun16
EOF

# 2. Имя хоста и файл hosts
read -rp "Введите имя компьютера (hostname, например arch-nitro): " HOSTNAME
HOSTNAME=${HOSTNAME:-arch-nitro}
echo "$HOSTNAME" > /etc/hostname

cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# 3. Пароль root и создание пользователя
echo -e "\n${YELLOW}Задайте пароль для администратора root:${NC}"
passwd

read -rp "Введите имя нового пользователя (латиницей, например slemen): " username
username=${username:-slemen}
useradd -m -G wheel,audio,video,storage -s /bin/bash "$username"
echo -e "${YELLOW}Задайте пароль для пользователя $username:${NC}"
passwd "$username"

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 4. Ускорение pacman, включение [multilib] и многопоточная сборка makepkg
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
grep -q "^ILoveCandy" /etc/pacman.conf || sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/}' /etc/pacman.conf

sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
pacman -Sy --noconfirm

# 5. Установка KDE Plasma 6, драйверов Intel, звука PipeWire и утилит
echo -e "\n${YELLOW}Установка KDE Plasma 6, PipeWire, ZRAM и системных утилит...${NC}"
pacman -S --noconfirm --needed \
    xorg-xwayland \
    plasma-meta konsole dolphin kate ark spectacle gwenview kcalc \
    sddm sddm-kcm \
    mesa vulkan-intel intel-media-driver \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber gst-plugin-pipewire \
    bluez bluez-utils \
    networkmanager network-manager-applet networkmanager-openvpn usb_modeswitch \
    power-profiles-daemon \
    zram-generator earlyoom reflector pacman-contrib \
    fish starship fzf gvfs-mtp tig highlight p7zip unrar unzip \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji

# Переключение оболочки пользователя на Fish после установки пакета
chsh -s /bin/fish "$username"

# 6. Настройка сжатой памяти ZRAM (zstd)
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# 7. Твики ядра sysctl (CachyOS) и планировщик NVMe
cat << 'EOF' > /etc/sysctl.d/99-performance-tweaks.conf
# Игровой лимит областей памяти (Steam / Proton)
vm.max_map_count = 2147483642

# Плавный сброс кэша на NVMe SSD без микрофризов
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.dirty_writeback_centisecs = 1500

# Оптимизация ZRAM и кэша VFS
vm.page-cluster = 0
vm.vfs_cache_pressure = 50

# Отключение NMI watchdog и разрешающий режим i915 perf
kernel.nmi_watchdog = 0
dev.i915.perf_stream_paranoid = 0

# Сетевой стек Google BBR и буферы
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 16384
EOF

cat << 'EOF' > /etc/udev/rules.d/60-ioschedulers.rules
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
EOF

# 8. Блокировка аппаратного watchdog Intel (iTCO_wdt)
cat << 'EOF' > /etc/modprobe.d/watchdog.conf
blacklist iTCO_vendor_support
blacklist iTCO_wdt
EOF

# 9. Сборка yay-bin из AUR от имени пользователя
echo -e "\n${YELLOW}Сборка AUR-помощника yay-bin...${NC}"
sudo -u "$username" bash -c '
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd /tmp && rm -rf yay-bin
'

# 10. Персональная настройка Konsole (Newbl1nk), Fish, Starship, .nanorc и Wayland
USER_HOME="/home/${username}"
mkdir -p "${USER_HOME}/.local/share/konsole"
mkdir -p "${USER_HOME}/.config/fish"
mkdir -p "${USER_HOME}/.config/environment.d"

cat << 'EOF' > "${USER_HOME}/.local/share/konsole/Newbl1nk.colorscheme"
[Background]
Color=27,35,44

[BackgroundFaint]
Color=18,18,18

[BackgroundIntense]
Color=18,18,18

[Color0]
Color=27,29,30

[Color0Faint]
Color=27,29,30

[Color0Intense]
Color=80,83,84

[Color1]
Color=249,38,114

[Color1Faint]
Color=249,38,114

[Color1Intense]
Color=255,0,0

[Color2]
Color=130,180,20

[Color2Faint]
Color=130,180,20

[Color2Intense]
Color=125,214,66

[Color3]
Color=253,151,31

[Color3Faint]
Color=253,151,31

[Color3Intense]
Color=254,237,108

[Color4]
Color=78,130,170

[Color4Faint]
Color=78,130,170

[Color4Intense]
Color=12,115,194

[Color5]
Color=140,84,254

[Color5Faint]
Color=140,84,254

[Color5Intense]
Color=158,111,254

[Color6]
Color=108,130,134

[Color6Faint]
Color=70,84,87

[Color6Intense]
Color=137,156,161

[Color7]
Color=204,204,198

[Color7Faint]
Color=204,204,198

[Color7Intense]
Color=248,248,242

[Foreground]
Color=204,204,204

[ForegroundFaint]
Color=160,160,160

[ForegroundIntense]
Color=255,255,255

[General]
Blur=false
ColorRandomization=false
Description=New bl1nk
Opacity=1
Wallpaper=
EOF

cat << 'EOF' > "${USER_HOME}/.local/share/konsole/Fish.profile"
[Appearance]
ColorScheme=Newbl1nk
Font=JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[General]
Command=/bin/fish
Name=Fish
Parent=FALLBACK/
EOF

cat << 'EOF' > "${USER_HOME}/.config/konsolerc"
[Desktop Entry]
DefaultProfile=Fish.profile
EOF

cat << 'EOF' > "${USER_HOME}/.config/starship.toml"
add_newline = false

[character]
success_symbol = "[·❯❯](bold green)"
error_symbol = "[✗](bold red)[❯](bold yellow)[❯](bold green)"

[directory]
read_only = " 🔒"
read_only_style = "cyan"

[git_branch]
symbol = "[ ](bold green)"
truncation_length = 6
truncation_symbol = ""

[git_commit]
commit_hash_length = 4
tag_symbol = "🔖 "

[git_status]
conflicted = "🏳 "
ahead = "🏎💨"
behind = "😰"
diverged = "😵"
untracked = "🤷‍"
stashed = "📦 "
modified = "📝"
staged = '[++\($count\)](green)'
renamed = "👅"
deleted = "🗑 "
EOF

cat << 'EOF' > "${USER_HOME}/.config/fish/config.fish"
set -g -x fish_greeting ''
if status is-interactive
    starship init fish | source
end
EOF

cat << 'EOF' > "${USER_HOME}/.nanorc"
set historylog
set linenumbers
set titlecolor bold,lightwhite,blue
set statuscolor bold,green
set errorcolor bold,lightwhite,red
set stripecolor ,yellow
set numbercolor bold,cyan
set keycolor bold,green
bind ^S savefile main
include "/usr/share/nano/*.nanorc"
EOF
cp "${USER_HOME}/.nanorc" /root/.nanorc

cat << 'EOF' > "${USER_HOME}/.config/environment.d/wayland.conf"
ELECTRON_OZONE_PLATFORM_HINT=auto
MOZ_ENABLE_WAYLAND=1
EOF

chown -R "${username}:${username}" "${USER_HOME}"

# 11. Установка загрузчика GRUB (UEFI)
echo -e "\n${YELLOW}Установка и настройка загрузчика GRUB...${NC}"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# 12. Включение системных служб
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl enable power-profiles-daemon.service
systemctl enable earlyoom.service
systemctl enable fstrim.timer
systemctl enable paccache.timer

echo -e "${GREEN}Настройка внутри chroot успешно завершена!${NC}"
