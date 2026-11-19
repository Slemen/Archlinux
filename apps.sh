#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ПОСТ-УСТАНОВОЧНЫЙ СКРИПТ ПРОГРАММ ДЛЯ ARCH LINUX (Steam, Office, Media, PipeWire)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Не запускайте этот скрипт напрямую от root! Запустите от обычного пользователя (sudo запросится автоматически).${NC}"
    exit 1
fi

echo -e "${CYAN}Для установки программ требуются права администратора.${NC}"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${CYAN}  УСТАНОВКА ПРОГРАММ И НАСТРОЙКА ЗВУКА PIPEWIRE (ARCH LINUX)${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Игры и утилиты Wine/Proton
echo -e "\n${YELLOW}[1/3] Установка Steam, GameMode и утилит Wine/Proton...${NC}"
sudo pacman -Syu --noconfirm --needed \
    steam \
    gamemode \
    lib32-gamemode \
    icoutils \
    cabextract \
    bc
echo -e "${GREEN}✔ Игровой пакет установлен.${NC}"

# 2. Офис и мультимедиа
echo -e "${YELLOW}[2/3] Установка LibreOffice, VLC, qBittorrent, yt-dlp и FFmpeg...${NC}"
sudo pacman -S --noconfirm --needed \
    libreoffice-fresh \
    libreoffice-fresh-ru \
    vlc \
    qbittorrent \
    yt-dlp \
    ffmpeg
echo -e "${GREEN}✔ Офисные и мультимедиа-программы установлены.${NC}"

# 3. Настройка игрового буфера звука PipeWire
echo -e "${YELLOW}[3/3] Настройка игрового буфера звука PipeWire (min-quantum = 1024)...${NC}"
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat << 'EOF' > "$HOME/.config/pipewire/pipewire.conf.d/99-gaming-audio.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.min-quantum = 1024
}
EOF
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
echo -e "${GREEN}✔ Игровой буфер PipeWire применён.${NC}"

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Установка программ завершена!${NC}"
echo -e "${GREEN}======================================================================${NC}"
