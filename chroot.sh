#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# НАСТРОЙКА СИСТЕМЫ ВНУТРИ ARCH-CHROOT (KDE Plasma 6 + Wayland + Fish + ZRAM)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  НАСТРОЙКА СИСТЕМЫ В CHROOT (KDE Plasma 6 + Оптимизации + Fish)      ${NC}"
echo -e "${CYAN}======================================================================${NC}"

echo -e "\n${YELLOW}[1/10] Настройка часового пояса, локали и имени хоста...${NC}"
ln -sf /usr/share/zoneinfo/Europe/Kyiv /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "KEYMAP=ruwin_alt_sh-UTF-8" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf

read -rp "Введите имя компьютера (hostname, например arch-nitro): " hostname
hostname=${hostname:-arch-nitro}
echo "$hostname" > /etc/hostname

cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain ${hostname}
EOF

echo -e "\n${YELLOW}[2/10] Настройка пароля root и создание пользователя...${NC}"
echo "Задайте пароль для root:"
passwd

read -rp "Введите имя нового пользователя (например, slemen): " username
useradd -m -G wheel,audio,video,storage -s /bin/bash "$username"
echo "Задайте пароль для пользователя $username:"
passwd "$username"

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo -e "\n${YELLOW}[3/10] Оптимизация pacman (ParallelDownloads, multilib) и makepkg...${NC}"
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
grep -q "ILoveCandy" /etc/pacman.conf || sed -i '/^Color/a ILoveCandy' /etc/pacman.conf

if grep -q "^#\[multilib\]" /etc/pacman.conf; then
    sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/}' /etc/pacman.conf
fi

sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
pacman -Syu --noconfirm

echo -e "\n${YELLOW}[4/10] Установка KDE Plasma 6, графики Intel, звука и утилит...${NC}"
pacman -S --noconfirm --needed \
    xorg-xwayland plasma-meta konsole dolphin kate ark spectacle gwenview kcalc \
    sddm packagekit-qt6 flatpak \
    mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber gst-plugin-pipewire \
    bluez bluez-utils networkmanager-openvpn network-manager-applet usb_modeswitch \
    power-profiles-daemon timeshift pacman-contrib zram-generator earlyoom \
    fish fzf starship gvfs-mtp tig git github-cli haveged highlight \
    aspell aspell-en aspell-ru hunspell hunspell-en_us hunspell-ru \
    ttf-jetbrains-mono-nerd ttf-dejavu noto-fonts noto-fonts-cjk noto-fonts-emoji

chsh -s /bin/fish "$username"

echo -e "\n${YELLOW}[5/10] Настройка сжатой памяти ZRAM (zstd) и лимита логов journald...${NC}"
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

mkdir -p /etc/systemd/journald.conf.d
cat << 'EOF' > /etc/systemd/journald.conf.d/99-size-limit.conf
[Journal]
SystemMaxUse=150M
RuntimeMaxUse=50M
EOF

echo -e "\n${YELLOW}[6/10] Применение ядерных твиков sysctl (CachyOS/Nobara), Wi-Fi, udev и блокировка iTCO_wdt...${NC}"
cat << 'EOF' > /etc/modules-load.d/network-tuning.conf
tcp_bbr
sch_cake
EOF

cat << 'EOF' > /etc/sysctl.d/99-performance-tweaks.conf
vm.swappiness = 180
vm.max_map_count = 2147483642
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.dirty_writeback_centisecs = 1500
vm.page-cluster = 0
vm.vfs_cache_pressure = 50
vm.compaction_proactiveness = 0
fs.file-max = 2097152
kernel.nmi_watchdog = 0
kernel.split_lock_mitigate = 0
dev.i915.perf_stream_paranoid = 0
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 16384
EOF

mkdir -p /etc/NetworkManager/conf.d
cat << 'EOF' > /etc/NetworkManager/conf.d/wifi-powersave-off.conf
[connection]
wifi.powersave = 2
EOF

cat << 'EOF' > /etc/udev/rules.d/99-gaming-optimizations.rules
KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
EOF

cat << 'EOF' > /etc/modprobe.d/watchdog.conf
blacklist iTCO_vendor_support
blacklist iTCO_wdt
install iTCO_wdt /bin/true
install iTCO_vendor_support /bin/true
EOF

echo -e "\n${YELLOW}[7/10] Настройка Konsole (Newbl1nk, 10pt), Fish, Starship и .nanorc...${NC}"
USER_HOME="/home/${username}"
mkdir -p "${USER_HOME}/.local/share/konsole" "${USER_HOME}/.config/fish" "${USER_HOME}/.config/environment.d"

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
Font=JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

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

[cmd_duration]
disabled = true

[directory]
read_only = " 🔒"
read_only_style = "cyan"

[git_branch]
symbol = "[ ](bold green)"
truncation_length = 6
truncation_symbol = ""
EOF

cat << 'EOF' > "${USER_HOME}/.config/fish/config.fish"
set -g -x fish_greeting ''

alias upd='sudo pacman -Syu'
alias clean='sudo pacman -Sc --noconfirm && sudo paccache -rk2'
alias gpuinfo='nvidia-smi'
alias c='clear'

function pushall --description "Add, commit and push all changes"
    set -l msg "Update scripts"
    if test (count $argv) -gt 0
        set msg "$argv"
    end
    git add . && git commit -m "$msg" && git push
end

if status is-interactive
    starship init fish | source

    functions -c fish_prompt _starship_fish_prompt
    function fish_prompt
        if set -q CMD_DURATION; and test $CMD_DURATION -gt 2000
            set -l total_s (math -s0 "$CMD_DURATION / 1000")
            set -l m (math -s0 "$total_s / 60")
            set -l s (math "$total_s % 60")
            if test $m -gt 0
                echo -n (set_color --bold yellow)"[время: "$m"м "$s"с] "(set_color normal)
            else
                set -l s_dec (math -s1 "$CMD_DURATION / 1000")
                echo -n (set_color --bold yellow)"[время: "$s_dec"с] "(set_color normal)
            end
        end
        _starship_fish_prompt
    end
end
EOF

cat << 'EOF' > "${USER_HOME}/.config/environment.d/wayland.conf"
ELECTRON_OZONE_PLATFORM_HINT=auto
MOZ_ENABLE_WAYLAND=1
NVD_BACKEND=direct
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
include "/usr/share/nano-syntax-highlighting/*.nanorc"
EOF

cp "${USER_HOME}/.nanorc" /root/.nanorc
chown -R "${username}:${username}" "${USER_HOME}"

echo -e "\n${YELLOW}[8/10] Установка AUR-помощника yay-bin...${NC}"
su - "$username" -c "
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin &&
    cd /tmp/yay-bin &&
    makepkg -si --noconfirm &&
    rm -rf /tmp/yay-bin
"

echo -e "\n${YELLOW}[9/10] Включение системных служб...${NC}"
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl enable power-profiles-daemon.service
systemctl enable earlyoom.service
systemctl enable fstrim.timer
systemctl enable paccache.timer

mkdir -p /etc/pacman.d/hooks
cat << 'EOF' > /etc/pacman.d/hooks/10-timeshift-autosnap.hook
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux
Target = nvidia
Target = nvidia-utils
Target = mesa
Target = plasma-desktop

[Action]
Description = Создание снимка Btrfs в Timeshift перед обновлением критических пакетов...
When = PreTransaction
Exec = /bin/sh -c 'if [ -f /etc/timeshift/timeshift.json ] && command -v timeshift >/dev/null 2>&1; then /usr/bin/timeshift --create --comments "Pacman-Auto-Snap" --tags O --scripted; fi'
EOF

echo -e "\n${YELLOW}[10/10] Установка и настройка загрузчика GRUB (UEFI)...${NC}"
pacman -S --noconfirm --needed grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 modprobe.blacklist=iTCO_wdt,iTCO_vendor_support"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n${GREEN}Настройка chroot.sh успешно завершена!${NC}"
