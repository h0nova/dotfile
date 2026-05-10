#!/bin/bash
# Usage:
#   apply-theme.sh /path/to/wallpaper.jpg   — generate colors + set wallpaper
#   apply-theme.sh --reload                  — re-generate from current qs_colors.json

set -e

QS_COLORS="$HOME/.config/hypr/scripts/quickshell/qs_colors.json"
QS_USER="$HOME/.config/hypr/scripts/quickshell/qs_colors.user.json"

WALLPAPER="${1:-}"

if [ -z "$WALLPAPER" ]; then
    echo "Usage: apply-theme.sh /path/to/wallpaper.jpg"
    echo "       apply-theme.sh --reload"
    exit 1
fi

if [ "$WALLPAPER" != "--reload" ]; then
    if [ ! -f "$WALLPAPER" ]; then
        echo "Error: file not found: $WALLPAPER"
        exit 1
    fi
    echo "Generating colors from: $WALLPAPER"
    # matugen generates all configs + sets wallpaper via awww (see config.toml)
    matugen -m dark --prefer=saturation image "$WALLPAPER"
else
    # Reload: re-run matugen templates without regenerating colors
    matugen -m dark --prefer=saturation image --skip-wallpaper "$QS_COLORS" 2>/dev/null || \
    matugen -m dark --prefer=saturation image "$QS_COLORS" 2>/dev/null || true
fi

# Apply quickshell user overrides on top of generated qs_colors.json
if [ -f "$QS_USER" ]; then
    python3 - "$QS_COLORS" "$QS_USER" <<'EOF'
import json, sys
with open(sys.argv[1]) as f: base = json.load(f)
with open(sys.argv[2]) as f: overrides = json.load(f)
real = {k: v for k, v in overrides.items() if not k.startswith("_")}
if real:
    base.update(real)
    with open(sys.argv[1], "w") as f: json.dump(base, f, indent=2)
    print(f"Applied {len(real)} quickshell override(s): {', '.join(real.keys())}")
EOF
fi

# Qt/Kvantum color scheme (not handled by matugen)
if python3 "$HOME/.config/hypr/scripts/generate-qt-colors.py" 2>/dev/null; then
    echo "Qt colors generated"
fi

# Wallbash-Gtk GTK3 theme (HyDE base with dynamic palette)
if python3 "$HOME/.config/hypr/scripts/generate-gtk3-theme.py" 2>/dev/null; then
    echo "Wallbash-Gtk GTK3 theme generated"
    pkill xsettingsd 2>/dev/null; xsettingsd &
fi

# Hyprlock colors
if [ -f "$HOME/.config/hypr/hyprlock.conf" ]; then
    python3 - <<EOF
import json, re
from pathlib import Path
with open("$QS_COLORS") as f: c = json.load(f)
def h(k, a="ff"): return c[k].lstrip("#") + a
cfg = Path.home() / ".config/hypr/hyprlock.conf"
s = cfg.read_text()
s = re.sub(r'(color\s*=\s*rgba\()[0-9a-fA-F]+(,)', lambda m: m.group(0), s)
replacements = {
    "dee4deff": h("text"),
    "bfc9c2cc": h("subtext0", "cc"),
    "bfc9c2":   h("subtext0", ""),
    "8cd5b5bb": h("blue", "bb"),
    "8cd5b5ff": h("blue"),
    "1b211ef0": h("surface0", "f0"),
    "ffb4abff": h("red"),
    "a2ced8ff": h("peach"),
    "0a0f0dcc": h("crust", "cc"),
}
for old, new in replacements.items():
    s = s.replace(old, new)
cfg.write_text(s)
print("Hyprlock colors updated")
EOF
fi

# Spicetify color scheme
if python3 "$HOME/.config/hypr/scripts/generate-spicetify-colors.py" 2>/dev/null; then
    echo "Spicetify colors generated"
fi

# Quickshell picks up qs_colors.json automatically within ~1 second
echo "Done. Quickshell updates automatically within 1 second."
