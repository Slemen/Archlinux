#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ПОСТ-УСТАНОВОЧНЫЙ СКРИПТ ПРОГРАММ ДЛЯ ARCH LINUX (Steam, nvgame, Медиа, Звук)
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

echo -e "${CYAN}Для установки программ требуются права администратора.${NC}"
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${CYAN}  УСТАНОВКА ПРОГРАММ, NVGAME И НАСТРОЙКА PIPEWIRE (ACER NITRO V15-51)  ${NC}"
echo -e "${CYAN}======================================================================${NC}"

echo -e "\n${YELLOW}[1/3] Установка Steam, GameMode, кодеков и повседневных программ...${NC}"
sudo pacman -Syu --noconfirm --needed \
    steam gamemode lib32-gamemode bc \
    libreoffice-fresh libreoffice-fresh-ru vlc qbittorrent yt-dlp ffmpeg
sudo usermod -aG gamemode "$USER" 2>/dev/null || true
echo -e "${GREEN}✔ Программы и игровой стек установлены.${NC}"

echo -e "\n${YELLOW}[2/3] Создание игрового враппера /usr/local/bin/nvgame (кэш 10 ГБ + DXVK)...${NC}"
mkdir -p "$HOME/.local/share/Steam" "$HOME/.cache/nvidia/GLCache"

if command -v balooctl6 >/dev/null 2>&1; then
    balooctl6 config add excludeFolders "$HOME/.local/share/Steam" 2>/dev/null || true
fi

sudo tee /usr/local/bin/nvgame > /dev/null << 'EOF'
#!/usr/bin/env bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# Расширенный кэш шейдеров NVIDIA и DXVK на NVMe (10 ГБ) без автоочистки
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=10737418240
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nvidia/GLCache"
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="$HOME/.cache/nvidia"

# Оптимизация потоков OpenGL/DXVK и буфера звука
export __GL_THREADED_OPTIMIZATIONS=1
export PULSE_LATENCY_MSEC=60

# Отключение лишних фоновых слоёв Vulkan
export VK_LOADER_LAYERS_DISABLE="~implicit~"

mkdir -p "$__GL_SHADER_DISK_CACHE_PATH" "$DXVK_STATE_CACHE_PATH"
exec gamemoderun "$@"
EOF
sudo chmod +x /usr/local/bin/nvgame
echo -e "${GREEN}✔ Враппер nvgame создан (запуск в Steam: nvgame %command%).${NC}"

echo -e "\n${YELLOW}[3/3] Настройка звукового сервера PipeWire (игровой буфер)...${NC}"
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat << 'EOF' > "$HOME/.config/pipewire/pipewire.conf.d/99-gaming-audio.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.min-quantum = 1024
}
EOF

systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
echo -e "${GREEN}✔ Звуковая подсистема PipeWire настроена.${NC}"

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Установка программ и враппера nvgame успешно завершена!               ${NC}"
echo -e "${GREEN}======================================================================${NC}"
