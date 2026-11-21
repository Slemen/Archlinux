#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ПОСТ-УСТАНОВОЧНЫЙ СКРИПТ ДРАЙВЕРОВ NVIDIA ДЛЯ ARCH LINUX (Wayland / KDE Plasma)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Не запускайте этот скрипт напрямую от root! Запустите от обычного пользователя.${NC}"
    exit 1
fi

echo -e "${CYAN}Для установки и настройки драйверов NVIDIA требуются права администратора.${NC}"
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${CYAN}  УСТАНОВКА И НАСТРОЙКА ДРАЙВЕРОВ NVIDIA (Wayland + PRIME + Boost)    ${NC}"
echo -e "${CYAN}======================================================================${NC}"

echo -e "\n${YELLOW}[1/6] Проверка репозитория [multilib] в /etc/pacman.conf...${NC}"
if grep -q "^#\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/}' /etc/pacman.conf
    echo -e "${GREEN}✔ Репозиторий [multilib] активирован.${NC}"
else
    echo -e "${GREEN}✔ Репозиторий [multilib] уже включён.${NC}"
fi

echo -e "${YELLOW}[2/6] Установка пакетов nvidia, nvidia-prime, Vulkan и VA-API...${NC}"
sudo pacman -Syu --noconfirm --needed \
    nvidia nvidia-utils lib32-nvidia-utils nvidia-settings nvidia-prime \
    opencl-nvidia lib32-opencl-nvidia libva-nvidia-driver \
    vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools mesa-utils
echo -e "${GREEN}✔ Драйверы NVIDIA и утилита prime-run успешно установлены.${NC}"

echo -e "${YELLOW}[3/6] Добавление модулей NVIDIA в /etc/mkinitcpio.conf...${NC}"
sudo cp -n /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
if ! grep -q "nvidia_drm" /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo sed -i 's/MODULES=( /MODULES=(/' /etc/mkinitcpio.conf
    echo -e "${GREEN}✔ Модули nvidia, nvidia_modeset, nvidia_uvm, nvidia_drm добавлены.${NC}"
else
    echo -e "${GREEN}✔ Модули NVIDIA уже присутствуют в mkinitcpio.conf.${NC}"
fi

echo -e "${YELLOW}[4/6] Настройка параметров GRUB для KDE Plasma Wayland...${NC}"
if [[ -f /etc/default/grub ]]; then
    sudo cp -n /etc/default/grub /etc/default/grub.bak
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1 nvidia-drm.fbdev=1"/' /etc/default/grub
        echo -e "${GREEN}✔ Параметры nvidia-drm.modeset=1 nvidia-drm.fbdev=1 добавлены в GRUB.${NC}"
    else
        echo -e "${GREEN}✔ Параметры nvidia-drm уже прописаны в GRUB.${NC}"
    fi
fi

echo -e "${YELLOW}[5/6] Настройка служб сна NVIDIA, Dynamic Boost и параметров modprobe...${NC}"
sudo tee /etc/modprobe.d/nvidia.conf > /dev/null << 'EOF'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
sudo systemctl enable nvidia-powerd.service 2>/dev/null || true
echo -e "${GREEN}✔ Службы сохранения видеопамяти и Dynamic Boost включены.${NC}"

echo -e "${YELLOW}[6/6] Создание pacman-хука /etc/pacman.d/hooks/nvidia.hook и пересборка initramfs...${NC}"
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/nvidia.hook > /dev/null << 'EOF'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux

[Action]
Description=Обновление модулей NVIDIA в initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF

sudo mkinitcpio -P
if [[ -f /etc/default/grub ]]; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Установка драйверов NVIDIA завершена! Перезагрузите систему (reboot).${NC}"
echo -e "${GREEN}======================================================================${NC}"
