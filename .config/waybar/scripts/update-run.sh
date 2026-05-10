#!/usr/bin/env bash
# Launched when clicking the updates icon in Waybar.
# Opens kitty, shows fastfetch, "types" the command and runs yay -Syu.

AURHLPR="pacman"

# --- typing effect ---
typewrite() {
    local text="$1"
    local delay="${2:-0.04}"
    for (( i = 0; i < ${#text}; i++ )); do
        printf '%s' "${text:$i:1}"
        sleep "$delay"
    done
    printf '\n'
}

# --- main logic (runs inside kitty) ---
main() {
    # system info
    fastfetch 2>/dev/null || neofetch 2>/dev/null || true
    echo

    # count updates
    local pacman_count aur_count
    pacman_count=$(pacman -Qu 2>/dev/null | wc -l)
    printf '\e[1;32m Updates available:\e[0m\n'
    printf '  \e[0;37m󰏖  Pacman + Chaotic-AUR:\e[0m \e[1m%s\e[0m\n' "$pacman_count"
    echo

    # --- simulate command typing ---
    printf '\e[1;32m❯\e[0m '
    typewrite "sudo pacman -Syu"

    echo
    sudo pacman -Syu
    echo

    printf '\e[1;32m Done! Press any key...\e[0m'
    read -r -n 1
}

# --- if script called with "run" argument — execute main ---
if [[ "$1" == "run" ]]; then
    main
    exit 0
fi

# --- otherwise open kitty and pass self inside ---
kitty \
    --title "System Update" \
    --override "font_size=12" \
    bash "$(realpath "$0")" run
