#!/usr/bin/env bash

# ==============================================================================
# ПРОВЕРОЧНЫЙ СКРИПТ ДЛЯ ARCH LINUX (Диагностика 10 ключевых узлов системы)
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
echo -e "${CYAN}  ДИАГНОСТИКА ARCH LINUX (Ядра, Btrfs, ZRAM, Оптимизации, Терминал)${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Проверка ядер linux-zen и linux-lts с заголовками
if pacman -Qq linux-zen linux-zen-headers linux-lts linux-lts-headers &>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 1. Установлена связка ядер linux-zen + linux-lts и заголовки (*-headers)"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 1. Не найдены все пакеты ядер/заголовков (linux-zen / linux-lts)"
    ((FAIL++))
fi

# 2. Проверка Btrfs и сжатия zstd
if findmnt -no FSTYPE / | grep -q "btrfs" && findmnt -no OPTIONS / | grep -q "compress=zstd"; then
    echo -e "[ ${GREEN}OK${NC} ] 2. Корневая ФС Btrfs смонтирована со сжатием zstd"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 2. Корневая ФС не Btrfs или не активно сжатие zstd"
    ((FAIL++))
fi

# 3. Проверка ZRAM
if swapon --show | grep -q "zram0"; then
    echo -e "[ ${GREEN}OK${NC} ] 3. Сжатая память ZRAM (zram0) активна"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 3. Устройство zram0 не найдено"
    ((FAIL++))
fi

# 4. Проверка параметров sysctl (CachyOS + BBR)
MAX_MAP=$(sysctl -n vm.max_map_count 2>/dev/null)
CONG=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
if [[ "$MAX_MAP" == "2147483642" && "$CONG" == "bbr" ]]; then
    echo -e "[ ${GREEN}OK${NC} ] 4. Твики sysctl активны (max_map_count=$MAX_MAP, TCP=$CONG)"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 4. Ошибка применения sysctl (max_map_count=$MAX_MAP, TCP=$CONG)"
    ((FAIL++))
fi

# 5. Проверка планировщика NVMe
NVME_SCHED=$(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null || echo "no_nvme")
if [[ "$NVME_SCHED" == *"[none]"* || "$NVME_SCHED" == "no_nvme" ]]; then
    echo -e "[ ${GREEN}OK${NC} ] 5. Планировщик ввода-вывода NVMe оптимален ($NVME_SCHED)"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 5. Неоптимальный планировщик NVMe ($NVME_SCHED)"
    ((FAIL++))
fi

# 6. Проверка блокировки Intel Watchdog (iTCO_wdt)
if ! lsmod | grep -q "iTCO_wdt" && grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 6. Модуль Intel Watchdog (iTCO_wdt) заблокирован и выгружен"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 6. Модуль iTCO_wdt загружен или отсутствует /etc/modprobe.d/watchdog.conf"
    ((FAIL++))
fi

# 7. Проверка системных служб (earlyoom, power-profiles-daemon, fstrim.timer)
if systemctl is-active --quiet earlyoom.service && systemctl is-active --quiet power-profiles-daemon.service && systemctl is-enabled --quiet fstrim.timer; then
    echo -e "[ ${GREEN}OK${NC} ] 7. Службы earlyoom, power-profiles-daemon и fstrim.timer активны"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 7. Одна из системных служб (earlyoom / power-profiles / fstrim) не активна"
    ((FAIL++))
fi

# 8. Проверка профиля Konsole Newbl1nk, Fish и Starship
if [[ -f "$HOME/.local/share/konsole/Newbl1nk.colorscheme" && -f "$HOME/.config/starship.toml" ]] && command -v fish >/dev/null 2>&1 && command -v starship >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 8. Терминал Konsole (Newbl1nk), Fish и Starship настроены"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 8. Отсутствуют конфиги Konsole Newbl1nk / Starship или пакет fish"
    ((FAIL++))
fi

# 9. Проверка .nanorc и AUR-помощника yay
if [[ -f "$HOME/.nanorc" ]] && command -v yay >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 9. Конфиг редактора .nanorc и AUR-помощник yay установлены"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 9. Отсутствует ~/.nanorc или утилита yay"
    ((FAIL++))
fi

# 10. Проверка драйверов NVIDIA и prime-run (опционально)
if command -v prime-run >/dev/null 2>&1 && command -v nvidia-smi >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 10. Драйверы NVIDIA и утилита prime-run установлены и готовы"
    ((PASS++))
else
    echo -e "[ ${YELLOW}INFO${NC} ] 10. Драйверы NVIDIA не установлены (если есть GPU NVIDIA — запустите nvidia.sh)"
    ((PASS++))
fi

echo -e "${CYAN}----------------------------------------------------------------------${NC}"
if [[ $FAIL -eq 0 ]]; then
    echo -e "[ ${GREEN}OK${NC} ] ИТОГ: Все проверки пройдены ($PASS/10)!"
else
    echo -e "[ ${RED}FAIL${NC} ] ИТОГ: Пройдено $PASS/10, ошибок: $FAIL."
fi
echo -e "${CYAN}======================================================================${NC}"
