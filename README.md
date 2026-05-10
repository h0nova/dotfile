<div align="center">

# h0nova dotfiles

**Hyprland rice with dynamic Material You color theming**

*Colors generate automatically from your wallpaper — every app updates at once*

</div>

---

## Overview

| Component | Tool |
|-----------|------|
| Compositor | [Hyprland](https://hyprland.org) |
| Status bar | [Waybar](https://github.com/Alexays/Waybar) |
| Dynamic Island | [Quickshell](https://quickshell.outfoxxed.me) |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| Shell | Zsh + Oh My Zsh |
| Prompt | [Starship](https://starship.rs) |
| Fetch | [Fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| Wallpaper | [awww](https://github.com/xyproto/wallutils) |
| Color generation | [matugen](https://github.com/InioX/matugen) |
| Lock screen | [Hyprlock](https://github.com/hyprwm/hyprlock) |
| Idle daemon | [Hypridle](https://github.com/hyprwm/hypridle) |
| Power menu | [wlogout](https://github.com/ArtsyMacaw/wlogout) |
| App launcher | Dynamic Island (built-in) |
| File manager | [Dolphin](https://apps.kde.org/dolphin/) |
| Color picker | [Hyprpicker](https://github.com/hyprwm/hyprpicker) |
| Cursor | [Bibata Modern Ice](https://github.com/ful1e5/Bibata_Cursor) |
| Icons | [Tela Circle](https://github.com/vinceliuice/Tela-circle-icon-theme) |
| GTK theme | Wallbash-Gtk (dynamic) |
| Qt/Kvantum | Wallbash (dynamic) |
| Spotify | [Spicetify](https://spicetify.app) + Comfy theme |

---

## Color Pipeline

Changing a wallpaper updates **everything** automatically:

```
Wallpaper → matugen → qs_colors.json
                    ↓
     ┌──────────────┼──────────────┐
  Hyprland      Waybar          Kitty
  borders       colors          colors
     │
  GTK3/4     Qt/Kvantum     Hyprlock
  theme       colors         colors
     │
  Firefox    Spicetify
  theme      theme
```

Run manually:
```bash
apply-theme.sh ~/Pictures/Wallpapers/your-wallpaper.jpg
```

---

## Installation

### Requirements

- Arch Linux (or Arch-based distro)
- `yay` AUR helper (installed automatically if missing)

### Install

```bash
git clone https://github.com/h0nova/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

The script will:
1. Install all required packages (pacman + AUR)
2. Back up your existing configs to `~/.dotfiles-backup/`
3. Copy dotfiles to `~/.config/`
4. Replace hardcoded paths with your username
5. Set up Spicetify + Comfy theme
6. Set Zsh as default shell
7. Apply Bibata cursor theme
8. Apply initial color theme from your first wallpaper

### After Installation

1. Log out and log back in
2. Add wallpapers to `~/Pictures/Wallpapers/`
3. Fill in your OpenWeather API key for the weather widget:
   ```
   ~/.config/hypr/scripts/quickshell/calendar/.env
   ```
   Get a free key at [openweathermap.org](https://openweathermap.org/api)

4. Apply a theme:
   ```bash
   apply-theme.sh ~/Pictures/Wallpapers/your-wallpaper.jpg
   ```

---

## Packages

### Pacman

```
hyprland hyprlock hypridle hyprpicker xdg-desktop-portal-hyprland
waybar kitty starship fastfetch matugen
polkit-kde-agent gnome-keyring libsecret xsettingsd
brightnessctl playerctl cliphist wl-clipboard grim slurp pamixer
python zsh zsh-autosuggestions zsh-syntax-highlighting
pacman-contrib dolphin qt6ct kvantum wlogout
noto-fonts-emoji ttf-jetbrains-mono-nerd
```

### AUR

```
quickshell-git awww bibata-cursor-theme-bin
spotify-launcher spicetify-bin oh-my-zsh-git zsh-completions
```

---

## Keybinds

### General

| Keybind | Action |
|---------|--------|
| `Super + T` | Terminal (Kitty) |
| `Super + B` | Browser (Firefox) |
| `Super + E` | File manager (Dolphin) |
| `Super + Q` | Close window |
| `Super + V` | Toggle floating |
| `Super + J` | Toggle split |

### Dynamic Island

| Keybind | Action |
|---------|--------|
| `Super + A` | App launcher |
| `Super + C` | Clipboard history |
| `Super + N` | Notifications |

### Screenshots & Tools

| Keybind | Action |
|---------|--------|
| `Super + P` | Screenshot |
| `Super + Shift + P` | Color picker |

### System

| Keybind | Action |
|---------|--------|
| `Super + L` | Lock screen |
| `Ctrl + Alt + Del` | Power menu |

### Workspaces

| Keybind | Action |
|---------|--------|
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + Ctrl + →/←` | Next / previous workspace |
| `Super + Arrow keys` | Move focus |
| `Super + Shift + Arrow keys` | Resize window |

---

## Structure

```
dotfiles/
├── install.sh                   # Installation script
├── .zshrc                       # Zsh config
└── .config/
    ├── hypr/
    │   ├── hyprland.conf        # Main Hyprland config
    │   ├── hyprlock.conf        # Lock screen
    │   ├── hypridle.conf        # Idle daemon
    │   ├── settings.json        # UI settings (scale, wallpaper dir)
    │   └── scripts/
    │       ├── apply-theme.sh   # Main theming script
    │       ├── generate-*.py    # Color generators (Qt, GTK3, Spicetify)
    │       └── quickshell/      # Dynamic Island QML source
    ├── waybar/                  # Status bar config + styles
    ├── matugen/                 # Color templates for all apps
    ├── kitty/                   # Terminal config
    ├── fastfetch/               # System info + avatar assets
    ├── wlogout/                 # Power menu layout + icons
    ├── spicetify/Themes/Comfy/  # Spotify theme
    ├── gtk-3.0/                 # GTK3 settings
    ├── gtk-4.0/                 # GTK4 + libadwaita
    ├── Kvantum/                 # Qt Kvantum theme (wallbash)
    └── qt6ct/                   # Qt6 color config
```

---

## Credits

- [HyDE Project](https://github.com/hyde-project/hyde) — Wallbash theming approach, wlogout icons
- [ActivSpot / Quickshell](https://github.com/PaideiaDilemma/ActivSpot) — Dynamic Island base
- [matugen](https://github.com/InioX/matugen) — Material You color generation
- [Comfy Themes](https://github.com/Comfy-Themes/Spicetify) — Spotify Comfy theme
- [yugaaank](https://github.com/yugaaank/dotfiles) — Fastfetch layout inspiration
