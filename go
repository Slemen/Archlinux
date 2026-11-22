#!/usr/bin/env bash
curl -fsSL "https://slemen.github.io/Archlinux/base.sh?t=$(date +%s)" -o base.sh && chmod +x base.sh && ./base.sh </dev/tty
