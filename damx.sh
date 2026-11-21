#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# УСТАНОВКА DIV ACER MANAGER MAX (DAMX) ДЛЯ ARCH LINUX (ACER NITRO V15-51)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

WORK_DAMX="/tmp/damx_install"
SUDO_PID=""

on_exit() {
    local rc=$?
    if [[ -n "$SUDO_PID" ]]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
    rm -rf "$WORK_DAMX"
    if [[ $rc -ne 0 ]]; then
        echo -e "\n${RED}[ОШИБКА] Установка DAMX прервана.${NC}" >&2
    fi
}
trap on_exit EXIT

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Не запускайте этот скрипт напрямую от root! Запустите от обычного пользователя.${NC}"
    exit 1
fi

sudo -v
( while sleep 50; do sudo -n true 2>/dev/null || exit 0; done ) >/dev/null 2>&1 &
SUDO_PID=$!

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  УСТАНОВКА DIV ACER MANAGER MAX (DAMX) (ACER NITRO V15-51)           ${NC}"
echo -e "${CYAN}======================================================================${NC}"

echo -e "\n${YELLOW}[1/3] Установка сборочных зависимостей и заголовков ядра...${NC}"
sudo pacman -S --noconfirm --needed base-devel linux-headers git tar xz

echo -e "\n${YELLOW}[2/3] Поиск локального архива DAMX-*.tar.xz в папке Документы...${NC}"
rm -rf "$WORK_DAMX"
mkdir -p "$WORK_DAMX"

LOCAL_ARCHIVE=$(find "$HOME/Документы" "$HOME/Documents" -maxdepth 3 -name "DAMX-*.tar.xz" 2>/dev/null | head -n 1 || true)

if [[ -z "$LOCAL_ARCHIVE" || ! -f "$LOCAL_ARCHIVE" ]]; then
    echo -e "${RED}Архив DAMX-*.tar.xz не найден в ~/Документы (или ~/Documents).${NC}"
    echo -e "${YELLOW}Скачайте архив вручную из репозитория PXDiv / Div-Acer-Manager-Max (Releases на GitHub),${NC}"
    echo -e "${YELLOW}положите его в ~/Документы и запустите скрипт снова.${NC}"
    exit 1
fi

echo -e "${GREEN}Найден локальный архив: ${LOCAL_ARCHIVE}${NC}"
cp "$LOCAL_ARCHIVE" "$WORK_DAMX/damx.tar.xz"

if ! xz -t "$WORK_DAMX/damx.tar.xz" >/dev/null 2>&1; then
    echo -e "${RED}Файл ${LOCAL_ARCHIVE} повреждён или не является корректным архивом .tar.xz.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[3/3] Распаковка, патч ядра и запуск установщика DAMX...${NC}"
tar -xJf "$WORK_DAMX/damx.tar.xz" -C "$WORK_DAMX"

# Патч совместимости с актуальными ядрами Linux (замена strncpy на strscpy)
find "$WORK_DAMX" -name "linuwu_sense.c" -exec sed -i 's/\bstrncpy(/strscpy(/g' {} +

INSTALL_SCRIPT=$(find "$WORK_DAMX" -maxdepth 3 -name "setup.sh" | head -n 1 || true)
if [[ -z "$INSTALL_SCRIPT" ]]; then
    INSTALL_SCRIPT=$(find "$WORK_DAMX" -maxdepth 3 -name "install.sh" | head -n 1 || true)
fi

if [[ -z "$INSTALL_SCRIPT" ]]; then
    echo -e "${RED}Не найден внутренний скрипт setup.sh внутри архива DAMX.${NC}"
    exit 1
fi

chmod +x "$INSTALL_SCRIPT"
cd "$(dirname "$INSTALL_SCRIPT")"
sudo ./"$(basename "$INSTALL_SCRIPT")" </dev/tty

rm -f "$LOCAL_ARCHIVE"
echo -e "${CYAN}Установочный архив удалён из папки Документы.${NC}"

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}  DIV ACER MANAGER MAX (DAMX) УСПЕШНО УСТАНОВЛЕН!                     ${NC}"
echo -e "${CYAN}  Подсказка: клавишу Nitro для запуска команды DAMX назначьте сами в  ${NC}"
echo -e "${CYAN}  Параметры системы KDE -> Клавиатура -> Комбинации клавиш.           ${NC}"
echo -e "${GREEN}======================================================================${NC}"
