#!/usr/bin/env bash
set -e

# ── Colors ─────────────────────────────────────────────────────────────────────
GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; BLU='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLU}[INFO]${NC}  $1"; }
ok()      { echo -e "${GRN}[OK]${NC}    $1"; }
warn()    { echo -e "${YLW}[WARN]${NC}  $1"; }
err()     { echo -e "${RED}[ERR]${NC}   $1"; exit 1; }
section() { echo -e "\n${BLU}══════════════════════════════════════${NC}"; echo -e "${BLU}  $1${NC}"; echo -e "${BLU}══════════════════════════════════════${NC}"; }

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# ── 1. Sanity checks ───────────────────────────────────────────────────────────
section "Checking environment"

[[ "$EUID" -eq 0 ]] && err "Do not run as root"
command -v pacman &>/dev/null || err "This script requires Arch Linux"
ok "Running as $(whoami) on Arch Linux"

# Install yay if missing
if ! command -v yay &>/dev/null; then
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    rm -rf /tmp/yay-bin
    ok "yay installed"
fi

# ── 2. Install packages ────────────────────────────────────────────────────────
section "Installing packages"

PACMAN_PKGS=(
    hyprland hyprlock hypridle hyprpicker xdg-desktop-portal-hyprland
    waybar kitty starship fastfetch
    matugen polkit-kde-agent gnome-keyring libsecret
    xsettingsd brightnessctl playerctl
    cliphist wl-clipboard grim slurp pamixer
    python zsh zsh-autosuggestions zsh-syntax-highlighting
    pacman-contrib
    dolphin qt6ct kvantum
    noto-fonts-emoji ttf-jetbrains-mono-nerd
    wlogout
)

AUR_PKGS=(
    quickshell-git
    awww
    bibata-cursor-theme-bin
    spotify-launcher
    spicetify-bin
    oh-my-zsh-git
    zsh-completions
)

info "Installing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" 2>/dev/null || \
    warn "Some pacman packages may have failed — continuing"

info "Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}" 2>/dev/null || \
    warn "Some AUR packages may have failed — continuing"

ok "Packages installed"

# ── 3. Backup existing configs ─────────────────────────────────────────────────
section "Backing up existing configs"

CONFIGS=(hypr waybar kitty matugen wlogout fastfetch starship.toml gtk-3.0 gtk-4.0 Kvantum kvantum qt6ct)
mkdir -p "$BACKUP"

for cfg in "${CONFIGS[@]}"; do
    if [[ -e "$HOME/.config/$cfg" ]]; then
        cp -r "$HOME/.config/$cfg" "$BACKUP/$cfg"
        info "Backed up: ~/.config/$cfg"
    fi
done
[[ -e "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$BACKUP/.zshrc"
ok "Backups saved to $BACKUP"

# ── 4. Copy dotfiles ───────────────────────────────────────────────────────────
section "Copying dotfiles"

mkdir -p "$HOME/.config"

cp -r "$DOTS/.config/hypr"        "$HOME/.config/"
cp -r "$DOTS/.config/waybar"      "$HOME/.config/"
cp -r "$DOTS/.config/kitty"       "$HOME/.config/"
cp -r "$DOTS/.config/matugen"     "$HOME/.config/"
cp -r "$DOTS/.config/wlogout"     "$HOME/.config/"
cp -r "$DOTS/.config/fastfetch"   "$HOME/.config/"
cp -r "$DOTS/.config/gtk-3.0"     "$HOME/.config/"
cp -r "$DOTS/.config/gtk-4.0"     "$HOME/.config/"
cp -r "$DOTS/.config/Kvantum"     "$HOME/.config/"
cp -r "$DOTS/.config/kvantum"     "$HOME/.config/"
cp -r "$DOTS/.config/qt6ct"       "$HOME/.config/"
cp    "$DOTS/.config/starship.toml" "$HOME/.config/"
cp    "$DOTS/.zshrc"              "$HOME/.zshrc"

# Wallpaper directory
mkdir -p "$HOME/Pictures/Wallpapers"
ok "Dotfiles copied"

# ── 5. Replace hardcoded username ─────────────────────────────────────────────
section "Patching paths for user: $(whoami)"

OLD_HOME="/home/h0nova"
NEW_HOME="$HOME"

if [[ "$OLD_HOME" != "$NEW_HOME" ]]; then
    info "Replacing $OLD_HOME → $NEW_HOME"

    # wlogout icons paths
    sed -i "s|$OLD_HOME|$NEW_HOME|g" "$HOME/.config/wlogout/style.css"

    # hyprland wallpaper dir
    sed -i "s|$OLD_HOME/Pictures/Wallpapers|$NEW_HOME/Pictures/Wallpapers|g" \
        "$HOME/.config/hypr/hyprland.conf"

    # settings.json
    sed -i "s|$OLD_HOME/Pictures/Wallpapers|$NEW_HOME/Pictures/Wallpapers|g" \
        "$HOME/.config/hypr/settings.json"

    # matugen templates
    find "$HOME/.config/matugen" -type f | xargs sed -i "s|$OLD_HOME|$NEW_HOME|g" 2>/dev/null || true

    ok "Paths patched"
else
    ok "Same username — no patching needed"
fi

# ── 6. Spicetify setup ─────────────────────────────────────────────────────────
section "Setting up Spicetify"

SPOTIFY_PATH="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"

if [[ -d "$SPOTIFY_PATH" ]]; then
    chmod a+wr "$SPOTIFY_PATH"
    chmod a+wr "$SPOTIFY_PATH/Apps" -R 2>/dev/null || true

    spicetify config spotify_path "$SPOTIFY_PATH"
    spicetify config prefs_path "$HOME/.config/spotify/prefs"

    # Install Marketplace
    curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh

    # Copy Comfy theme
    if [[ -d "$DOTS/.config/spicetify/Themes/Comfy" ]]; then
        mkdir -p "$HOME/.config/spicetify/Themes"
        cp -r "$DOTS/.config/spicetify/Themes/Comfy" "$HOME/.config/spicetify/Themes/"
    fi

    spicetify backup apply 2>/dev/null || true
    ok "Spicetify configured"
else
    warn "Spotify not installed — skipping Spicetify setup"
fi

# ── 7. Set up Zsh ──────────────────────────────────────────────────────────────
section "Configuring Zsh"

if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    ok "Default shell changed to zsh (takes effect on next login)"
fi

# ── 8. Cursor theme ────────────────────────────────────────────────────────────
section "Applying cursor theme"

mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=Bibata-Modern-Ice
EOF

gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
ok "Cursor theme set"

# ── 9. Calendar .env template ──────────────────────────────────────────────────
section "Weather API setup"

ENV_FILE="$HOME/.config/hypr/scripts/quickshell/calendar/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" << 'EOF'
# Get your free API key at: https://openweathermap.org/api
OPENWEATHER_KEY=your_api_key_here
OPENWEATHER_CITY_ID=your_city_id_here
OPENWEATHER_UNIT=metric
EOF
    warn "Created .env template — fill in your OpenWeather API key:"
    warn "  $ENV_FILE"
fi

# ── 10. Apply initial theme ────────────────────────────────────────────────────
section "Applying initial theme"

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | head -1)

if [[ -n "$WALLPAPER" ]]; then
    info "Applying theme from: $WALLPAPER"
    bash "$HOME/.config/hypr/scripts/apply-theme.sh" "$WALLPAPER" 2>/dev/null || \
        warn "Theme apply failed — run manually after login: apply-theme.sh /path/to/wallpaper"
else
    warn "No wallpapers found in $WALLPAPER_DIR"
    warn "Add wallpapers and run: ~/.config/hypr/scripts/apply-theme.sh /path/to/wallpaper"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
section "Installation complete!"

echo -e "${GRN}"
echo "  ✓ All configs installed"
echo "  ✓ Packages installed"
echo "  ✓ Paths patched for: $HOME"
echo ""
echo "  Next steps:"
echo "  1. Log out and log back in (or restart)"
echo "  2. Add wallpapers to ~/Pictures/Wallpapers/"
echo "  3. Fill in OpenWeather API key in:"
echo "     ~/.config/hypr/scripts/quickshell/calendar/.env"
echo "  4. Run: apply-theme.sh ~/Pictures/Wallpapers/your-wallpaper.jpg"
echo -e "${NC}"
