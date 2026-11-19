#!/usr/bin/env bash

# ==============================================================================
# ПРОВЕРОЧНЫЙ СКРИПТ: Диагностика установленной системы Arch Linux (10 пунктов)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ПРОВЕРКА КОНФИГУРАЦИИ ARCH LINUX (KDE PLASMA 6 + OPTIMIZATIONS)${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Проверка установленных ядер и заголовков (linux-zen + linux-lts)
if pacman -Qq linux-zen linux-zen-headers linux-lts linux-lts-headers &>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 1. Ядра linux-zen и linux-lts вместе с заголовками (*-headers) установлены"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 1. Не найдены все пакеты ядер (linux-zen / linux-lts / *-headers)"
    ((FAIL++))
fi

# 2. Проверка файловой системы Btrfs со сжатием zstd
if findmnt -no FSTYPE,OPTIONS / | grep -q "btrfs.*compress=zstd"; then
    echo -e "[ ${GREEN}OK${NC} ] 2. Корневая ФС Btrfs смонтирована со сжатием zstd"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 2. Корневая ФС Btrfs не использует сжатие zstd"
    ((FAIL++))
fi

# 3. Проверка активного ZRAM (zstd)
if swapon --show | grep -q "zram0"; then
    echo -e "[ ${GREEN}OK${NC} ] 3. Сжатая память ZRAM (zram0) активна"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 3. Устройство zram0 не активно"
    ((FAIL++))
fi

# 4. Проверка ядерных твиков sysctl (CachyOS / BBR)
MAP_CNT=$(sysctl -n vm.max_map_count 2>/dev/null)
BBR=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
if [[ "$MAP_CNT" == "2147483642" && "$BBR" == "bbr" ]]; then
    echo -e "[ ${GREEN}OK${NC} ] 4. Параметры sysctl (max_map_count=$MAP_CNT, TCP=$BBR) активны"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 4. Параметры sysctl не применились (map=$MAP_CNT, tcp=$BBR)"
    ((FAIL++))
fi

# 5. Проверка блокировки Intel Watchdog (iTCO_wdt)
if grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null && ! lsmod | grep -q "iTCO_wdt"; then
    echo -e "[ ${GREEN}OK${NC} ] 5. Модуль Intel Watchdog (iTCO_wdt) заблокирован и выгружен"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 5. Модуль iTCO_wdt не заблокирован или всё ещё загружен"
    ((FAIL++))
fi

# 6. Проверка ключевых системных служб
if systemctl is-active --quiet earlyoom.service && systemctl is-active --quiet power-profiles-daemon.service && systemctl is-enabled --quiet fstrim.timer; then
    echo -e "[ ${GREEN}OK${NC} ] 6. Службы earlyoom, power-profiles-daemon и таймер fstrim.timer активны"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 6. Одна из служб (earlyoom / power-profiles-daemon / fstrim.timer) не активна"
    ((FAIL++))
fi

# 7. Проверка темы Konsole Newbl1nk, Fish и Starship
if [[ -f "$HOME/.local/share/konsole/Newbl1nk.colorscheme" ]] && command -v fish >/dev/null 2>&1 && command -v starship >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 7. Терминал Konsole (Newbl1nk), Fish и Starship настроены"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 7. Отсутствуют компоненты терминала (Newbl1nk / Fish / Starship)"
    ((FAIL++))
fi

# 8. Проверка конфигов .nanorc
if [[ -f "$HOME/.nanorc" ]] && grep -q "set linenumbers" "$HOME/.nanorc" 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 8. Конфигурация редактора nano (~/.nanorc) применена"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 8. Файл ~/.nanorc не найден"
    ((FAIL++))
fi

# 9. Проверка AUR-помощника yay
if command -v yay >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 9. AUR-помощник yay установлен"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 9. Утилита yay не найдена"
    ((FAIL++))
fi

# 10. Проверка драйверов NVIDIA и prime-run (опционально после nvidia.sh)
if command -v prime-run >/dev/null 2>&1 && command -v nvidia-smi >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 10. Драйверы NVIDIA и утилита prime-run готовы к работе"
    ((PASS++))
else
    echo -e "[ ${YELLOW}INFO${NC} ] 10. Драйверы NVIDIA / prime-run ещё не установлены (запустите nvidia.sh при наличии GPU NVIDIA)"
    ((PASS++))
fi

echo -e "${CYAN}----------------------------------------------------------------------${NC}"
if [[ $FAIL -eq 0 ]]; then
    echo -e "[ ${GREEN}OK${NC} ] ИТОГ: Все проверки пройдены ($PASS/10)!"
else
    echo -e "[ ${RED}FAIL${NC} ] ИТОГ: Пройдено $PASS/10, ошибок: $FAIL."
fi
echo -e "${CYAN}======================================================================${NC}"
