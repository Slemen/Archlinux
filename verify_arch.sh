#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# ПРОВЕРОЧНЫЙ СКРИПТ ДЛЯ ARCH LINUX (Диагностика 15 ключевых узлов системы)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

ok()   { echo -e "[ ${GREEN}OK${NC} ] $1"; ((++PASS)); }
fail() { echo -e "[ ${RED}FAIL${NC} ] $1"; ((++FAIL)); }

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ДИАГНОСТИКА ARCH LINUX (15 ПУНКТОВ — ACER NITRO V15-51)             ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Штатное ядро linux и заголовки
if pacman -Qq linux linux-headers &>/dev/null; then
    ok "1. Установлено штатное ядро linux и заголовки linux-headers"
else
    fail "1. Не найдены пакеты linux / linux-headers"
fi

# 2. Btrfs, сжатие zstd и noatime
if findmnt -no FSTYPE / | grep -q "btrfs" && findmnt -no OPTIONS / | grep -q "compress=zstd" && findmnt -no OPTIONS / | grep -q "noatime"; then
    ok "2. Корневая ФС Btrfs смонтирована со сжатием zstd и опцией noatime"
else
    fail "2. Корневая ФС не Btrfs или отсутствуют опции compress=zstd / noatime"
fi

# 3. ZRAM и лимит journald
if swapon --show | grep -q "zram0" && [[ -f /etc/systemd/journald.conf.d/99-size-limit.conf ]]; then
    ok "3. Сжатая память ZRAM (zram0) активна, лимит логов journald (150 МБ) задан"
else
    fail "3. Устройство zram0 не найдено или не задан лимит логов journald"
fi

# 4. Параметры sysctl (CachyOS + CAKE + BBR)
if [[ "$(sysctl -n vm.max_map_count 2>/dev/null)" == "2147483642" ]] && \
   [[ "$(sysctl -n kernel.split_lock_mitigate 2>/dev/null)" == "0" ]] && \
   [[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" == "bbr" ]] && \
   [[ "$(sysctl -n net.core.default_qdisc 2>/dev/null)" == "cake" ]]; then
    ok "4. Твики sysctl (max_map_count, split_lock=0) и сеть CAKE + BBR активны"
else
    fail "4. Ошибка применения твиков sysctl или CAKE + BBR"
fi

# 5. Энергосбережение Wi-Fi отключено
if [[ -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf ]] && grep -q "wifi.powersave = 2" /etc/NetworkManager/conf.d/wifi-powersave-off.conf; then
    ok "5. Энергосбережение Wi-Fi отключено (wifi.powersave = 2)"
else
    fail "5. Конфигурация отключения энергосбережения Wi-Fi не найдена"
fi

# 6. Правила udev (ntsync и планировщик NVMe)
if [[ -f /etc/udev/rules.d/99-gaming-optimizations.rules ]] && grep -q "ntsync" /etc/udev/rules.d/99-gaming-optimizations.rules; then
    ok "6. Правила udev (ntsync и планировщик I/O NVMe) применены"
else
    fail "6. Правила udev 99-gaming-optimizations.rules не найдены"
fi

# 7. Блокировка Intel Watchdog (iTCO_wdt)
if ! lsmod | grep -q "^iTCO_wdt" && grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null; then
    ok "7. Модуль Intel Watchdog (iTCO_wdt) заблокирован и выгружен"
else
    fail "7. Модуль iTCO_wdt загружен или отсутствует /etc/modprobe.d/watchdog.conf"
fi

# 8. Системные службы
if systemctl is-active --quiet earlyoom.service && systemctl is-active --quiet power-profiles-daemon.service && systemctl is-enabled --quiet fstrim.timer; then
    ok "8. Службы earlyoom, power-profiles-daemon и fstrim.timer активны"
else
    fail "8. Одна из системных служб (earlyoom / power-profiles / fstrim) не активна"
fi

# 9. Konsole (Newbl1nk, 10pt), Fish (левый таймер) и Starship
if [[ -f "$HOME/.local/share/konsole/Newbl1nk.colorscheme" ]] && \
   grep -q "JetBrainsMono Nerd Font,10," "$HOME/.local/share/konsole/Fish.profile" 2>/dev/null && \
   grep -q "_starship_fish_prompt" "$HOME/.config/fish/config.fish" 2>/dev/null && \
   command -v starship >/dev/null 2>&1; then
    ok "9. Konsole (Newbl1nk, 10pt), Fish (левый таймер мин/сек) и Starship настроены"
else
    fail "9. Отсутствуют конфиги Konsole / Starship или левый таймер в Fish"
fi

# 10. Конфигурация Nano и AUR-помощник yay
if [[ -f "$HOME/.nanorc" ]] && sudo test -f /root/.nanorc && command -v yay >/dev/null 2>&1; then
    ok "10. Конфиг .nanorc (пользователь и root) и AUR-помощник yay установлены"
else
    fail "10. Отсутствует .nanorc или утилита yay"
fi

# 11. Драйверы NVIDIA, Dynamic Boost и prime-run
if command -v prime-run >/dev/null 2>&1 && command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    ok "11. Драйверы NVIDIA, Dynamic Boost и утилита prime-run активны"
else
    fail "11. Драйверы NVIDIA не активны (запустите nvidia.sh и перезагрузитесь)"
fi

# 12. Игровое окружение (Steam, GameMode и враппер nvgame 10 ГБ)
if command -v steam >/dev/null 2>&1 && command -v gamemoderun >/dev/null 2>&1 && [[ -x /usr/local/bin/nvgame ]] && \
   grep -q "__GL_SHADER_DISK_CACHE_SIZE=10737418240" /usr/local/bin/nvgame; then
    ok "12. Steam, GameMode и враппер nvgame (кэш 10 ГБ + DXVK) настроены"
else
    fail "12. Steam, GameMode или враппер nvgame не настроены"
fi

# 13. Конфигурация PipeWire и Wayland
if [[ -f "$HOME/.config/pipewire/pipewire.conf.d/99-gaming-audio.conf" ]] && [[ -f "$HOME/.config/environment.d/wayland.conf" ]]; then
    ok "13. Конфигурации PipeWire (min-quantum=1024) и Wayland созданы"
else
    fail "13. Отсутствуют конфиги PipeWire или Wayland"
fi

# 14. Div Acer Manager Max (DAMX)
if (command -v DAMX >/dev/null 2>&1 || [[ -x /usr/bin/DAMX ]] || systemctl list-unit-files | grep -qi "damx") && [[ -f /etc/pacman.d/hooks/95-linuwu-sense.hook ]]; then
    ok "14. Div Acer Manager Max (DAMX) установлен (клавиша настраивается вручную)"
else
    fail "14. Div Acer Manager Max (DAMX) не обнаружен (запустите damx.sh)"
fi

# 15. Упавшие службы systemd
FAILED_UNITS=$(systemctl --failed --no-legend | wc -l)
if [[ "$FAILED_UNITS" -eq 0 ]]; then
    ok "15. Упавшие системные службы (systemd failed units) отсутствуют"
else
    fail "15. Обнаружены упавшие службы systemd ($FAILED_UNITS шт.)"
fi

echo -e "${CYAN}----------------------------------------------------------------------${NC}"
echo -e "  ИТОГ ПРОВЕРКИ: ${GREEN}УСПЕШНО: ${PASS}${NC} | ${RED}ОШИБОК: ${FAIL}${NC}"
echo -e "${CYAN}======================================================================${NC}"
