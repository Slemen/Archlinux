#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ИНТЕРАКТИВНОЕ МЕНЮ ПОСТ-УСТАНОВКИ ARCH LINUX (Slemen/Archlinux)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO_BASE="https://slemen.github.io/Archlinux"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="/tmp/arch_slemen_post"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Не запускайте меню от имени root! Запустите от обычного пользователя.${NC}"
    exit 1
fi

run_script() {
    local script_name="$1"
    mkdir -p "$TMP_DIR"
    if [[ -f "${SCRIPT_DIR}/${script_name}" && "${SCRIPT_DIR}" != "/tmp" ]]; then
        echo -e "\n${CYAN}Запуск локального скрипта: ${script_name}${NC}"
        bash "${SCRIPT_DIR}/${script_name}" </dev/tty
    else
        local target_path="$TMP_DIR/$script_name"
        echo -e "\n${YELLOW}Загрузка актуального скрипта $script_name из репозитория...${NC}"
        curl -fsSL --retry 3 --retry-delay 2 "${REPO_BASE}/${script_name}?t=$(date +%s)" -o "$target_path"
        chmod +x "$target_path"
        bash "$target_path" </dev/tty
        rm -f "$target_path"
    fi
}

while true; do
    clear
    S1="[ ]"; command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1 && S1="${GREEN}[✓]${NC}"
    S2="[ ]"; [[ -x /usr/local/bin/nvgame ]] && S2="${GREEN}[✓]${NC}"
    S3="[ ]"; (command -v DAMX >/dev/null 2>&1 || [[ -x /usr/bin/DAMX ]] || systemctl list-unit-files | grep -qi "damx") && S3="${GREEN}[✓]${NC}"

    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${CYAN}  МЕНЮ ПОСТ-УСТАНОВКИ ARCH LINUX (Slemen/Archlinux — Acer Nitro V15)  ${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "  ${GREEN}1)${NC} ${S1} Установить драйверы NVIDIA (Wayland + PRIME + Dynamic Boost)"
    echo -e "  ${GREEN}2)${NC} ${S2} Установить программы (Steam, GameMode, nvgame, медиа, PipeWire)"
    echo -e "  ${GREEN}3)${NC} ${S3} Установить Div Acer Manager Max (DAMX — кулеры и батарея)"
    echo -e "  ${GREEN}4)${NC}     Запустить диагностику системы (15 пунктов — verify_arch.sh)"
    echo -e "  ${YELLOW}5)${NC}     Перезагрузить компьютер (reboot)"
    echo -e "  ${RED}0)${NC}     Выход"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    read -rp "Выберите действие [0-5]: " CHOICE </dev/tty

    case "$CHOICE" in
        1)
            run_script "nvidia.sh"
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        2)
            run_script "apps.sh"
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        3)
            run_script "damx.sh"
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        4)
            run_script "verify_arch.sh"
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        5)
            echo -e "${YELLOW}Перезагрузка системы через 3 секунды...${NC}"
            sleep 3
            sudo reboot
            ;;
        0)
            echo -e "${GREEN}Выход из меню.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Введите цифру от 0 до 5.${NC}"
            sleep 1
            ;;
    esac
done
