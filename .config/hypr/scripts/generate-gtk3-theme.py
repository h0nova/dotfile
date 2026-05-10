#!/usr/bin/env python3
import json, os, re

colors_path = os.path.expanduser("~/.config/hypr/scripts/quickshell/qs_colors.json")

with open(colors_path) as f:
    c = json.load(f)

INVALID_GTK3 = re.compile(
    r'^\s*(?:filter|transform|border-spacing|-gtk-icon-filter)\s*:.*$',
    re.MULTILINE
)

def patch(template_path, output_path, replacements):
    src = template_path if os.path.exists(template_path) else output_path
    with open(src) as f:
        css = f.read()
    for old, new in replacements:
        css = re.sub(re.escape(old), new, css, flags=re.IGNORECASE)
    css = INVALID_GTK3.sub('', css)
    with open(output_path, "w") as f:
        f.write(css)
    print(f"Generated {output_path}")

# Wallbash-Gtk color mapping
wallbash_replacements = [
    ("#FFCCCD", c["text"]),       # foreground / text
    ("#F0AAAC", c["subtext0"]),   # secondary text
    ("#E69A9C", c["blue"]),       # accent
    ("#1B1A29", c["base"]),       # dark background
    ("#2C2952", c["mantle"]),     # base input bg
    ("#3D3A6B", c["surface0"]),   # surface
    ("#4E4B7D", c["surface1"]),   # surface high
    ("#AADCF0", c["peach"]),      # secondary accent
    ("#9AD0E6", c["teal"]),       # teal secondary
    ("#F28B82", c["red"]),        # error
    ("#FDD633", c["peach"]),      # warning/yellow
]

wallbash_dir = os.path.expanduser("~/.local/share/themes/Wallbash-Gtk/gtk-3.0")
patch(f"{wallbash_dir}/gtk.css.template",      f"{wallbash_dir}/gtk.css",      wallbash_replacements)
patch(f"{wallbash_dir}/gtk-dark.css.template", f"{wallbash_dir}/gtk-dark.css", wallbash_replacements)
