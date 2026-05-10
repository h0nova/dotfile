#!/usr/bin/env bash
# Counts available updates. Uses checkupdates (no root needed) + yay for AUR.

# Pacman updates (syncs db safely via temp copy)
if command -v checkupdates &>/dev/null; then
    pacman_count=$(checkupdates 2>/dev/null | wc -l)
else
    pacman_count=$(pacman -Qu 2>/dev/null | wc -l)
fi

# AUR updates via yay
aur_count=$(yay -Qua 2>/dev/null | wc -l)

count=$(( pacman_count + aur_count ))

if (( count == 0 )); then
    printf '{"text": "", "tooltip": "System is up to date ✓", "class": "updated", "hidden": true}\n'
else
    tooltip="Updates available: $count\\n󰏗 Pacman: $pacman_count\\n󰏖 AUR: $aur_count"
    printf '{"text": "%d", "tooltip": "%s", "class": "updates"}\n' "$count" "$tooltip"
fi
