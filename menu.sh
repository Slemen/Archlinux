#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ИНТЕРАКТИВНОЕ МЕНЮ ПОСТ-УСТАНОВКИ ARCH LINUX (Slemen/Archlinux)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO_BASE="https://slemen.github.io/Archlinux"
TMP_DIR="/tmp/arch_slemen_post"
mkdir -p "$TMP_DIR"

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Не запускайте меню от имени root! Запустите от обычного пользователя.${NC}"
    exit 1
fi

run_remote_script() {
    local script_name="$1"
    local target_path="$TMP_DIR/$script_name"
    echo -e "\n${YELLOW}Загрузка актуального скрипта $script_name из репозитория...${NC}"
    curl -fsSL "$REPO_BASE/$script_name" -o "$target_path"
    chmod +x "$target_path"
    "$target_path"
}

while true; do
    echo -e "\n${CYAN}======================================================================${NC}"
    echo -e "${CYAN}  МЕНЮ ПОСТ-УСТАНОВКИ ARCH LINUX (Slemen/Archlinux)${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "  ${GREEN}1)${NC} Установить драйверы NVIDIA (nvidia-dkms + prime-run + Wayland)"
    echo -e "  ${GREEN}2)${NC} Установить программы (Steam, GameMode, LibreOffice, медиа, PipeWire)"
    echo -e "  ${GREEN}3)${NC} Выполнить всё сразу (NVIDIA + Программы)"
    echo -e "  ${GREEN}4)${NC} Запустить диагностику системы (verify_arch.sh)"
    echo -e "  ${GREEN}5)${NC} Перезагрузить компьютер (reboot)"
    echo -e "  ${RED}0)${NC} Выход"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    read -rp "Выберите действие [0-5]: " CHOICE

    case "$CHOICE" in
        1)
            run_remote_script "nvidia.sh"
            ;;
        2)
            run_remote_script "apps.sh"
            ;;
        3)
            run_remote_script "nvidia.sh"
            run_remote_script "apps.sh"
            ;;
        4)
            run_remote_script "verify_arch.sh"
            ;;
        5)
            read -rp "Точно перезагрузить компьютер сейчас? [y/N]: " REB
            if [[ "$REB" =~ ^[Yy]$ ]]; then
                sudo reboot
            fi
            ;;
        0)
            echo -e "${GREEN}Выход из меню.${NC}"
            rm -rf "$TMP_DIR"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Введите цифру от 0 до 5.${NC}"
            ;;
    esac
done
