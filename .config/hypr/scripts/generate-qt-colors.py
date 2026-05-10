#!/usr/bin/env python3
import json, os, re

colors_path = os.path.expanduser("~/.config/hypr/scripts/quickshell/qs_colors.json")
qt_colors_path = os.path.expanduser("~/.config/qt6ct/colors/dynamic.conf")
kvantum_cfg_path = os.path.expanduser("~/.config/Kvantum/dynamic/dynamic.kvconfig")

with open(colors_path) as f:
    c = json.load(f)

def hex_to_argb(h, alpha=255):
    h = h.lstrip('#')
    r, g, b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
    return f"#{alpha:02x}{r:02x}{g:02x}{b:02x}"

def darken(h, factor=0.8):
    h = h.lstrip('#')
    r, g, b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
    return f"#{int(r*factor):02x}{int(g*factor):02x}{int(b*factor):02x}"

def lighten(h, factor=1.2):
    h = h.lstrip('#')
    r, g, b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
    return f"#{min(255,int(r*factor)):02x}{min(255,int(g*factor)):02x}{min(255,int(b*factor)):02x}"

# Qt QPalette roles (order matters):
# WindowText, Button, Light, Midlight, Dark, Mid,
# Text, BrightText, ButtonText, Base, Window, Shadow,
# Highlight, HighlightedText, Link, LinkVisited,
# AlternateBase, NoRole, ToolTipBase, ToolTipText, PlaceholderText

def palette_row(fg, button, base, window, highlight, subtext):
    light   = lighten(button)
    midlight= button
    dark    = darken(button)
    mid     = darken(button, 0.9)
    shadow  = c['crust']
    alt_base= c['surface0']
    return (
        f"{hex_to_argb(fg)}, "          # WindowText
        f"{hex_to_argb(button)}, "       # Button
        f"{hex_to_argb(light)}, "        # Light
        f"{hex_to_argb(midlight)}, "     # Midlight
        f"{hex_to_argb(dark)}, "         # Dark
        f"{hex_to_argb(mid)}, "          # Mid
        f"{hex_to_argb(fg)}, "           # Text
        f"{hex_to_argb(fg)}, "           # BrightText
        f"{hex_to_argb(fg)}, "           # ButtonText
        f"{hex_to_argb(base)}, "         # Base
        f"{hex_to_argb(window)}, "       # Window
        f"{hex_to_argb(shadow)}, "       # Shadow
        f"{hex_to_argb(highlight)}, "    # Highlight
        f"{hex_to_argb(c['base'])}, "    # HighlightedText
        f"{hex_to_argb(highlight)}, "    # Link
        f"{hex_to_argb(c['mauve'])}, "   # LinkVisited
        f"{hex_to_argb(alt_base)}, "     # AlternateBase
        f"{hex_to_argb(c['base'])}, "    # NoRole
        f"{hex_to_argb(c['surface1'])}, "# ToolTipBase
        f"{hex_to_argb(fg)}, "           # ToolTipText
        f"{hex_to_argb(subtext, 180)}"   # PlaceholderText (semi-transparent)
    )

active   = palette_row(c['text'], c['surface1'], c['mantle'], c['base'], c['blue'], c['subtext1'])
disabled = palette_row(c['subtext1'], c['surface0'], c['mantle'], c['base'], c['surface2'], c['subtext1'])
inactive = active

qt_conf = f"""[ColorScheme]
active_colors={active}
disabled_colors={disabled}
inactive_colors={inactive}
"""

os.makedirs(os.path.dirname(qt_colors_path), exist_ok=True)
with open(qt_colors_path, "w") as f:
    f.write(qt_conf)
print(f"Generated {qt_colors_path}")

# Kvantum theme kvconfig (uses KvArcDark SVG as base, colors come from qt6ct)
kvconfig = """[%General]
author=dynamic
comment=Generated from qs_colors.json
x11drag=menubar_and_primary_toolbar
left_tabs=true
attach_active_tab=true
mirror_doc_tabs=true
composite=true
menu_shadow_depth=5
tooltip_shadow_depth=6
scroll_width=8
scroll_arrows=false
scroll_min_extent=50
slider_width=4
slider_handle_width=16
slider_handle_length=16
check_size=14
progressbar_thickness=3
menubar_mouse_tracking=true
toolbutton_style=1
drag_from_buttons=false
translucent_windows=false
blurring=false
popup_blurring=false
opaque_colors=false
contrast=1.0
intensity=1.0
saturation=1.0
no_window_pattern=false
reduce_window_opacity=0
reduce_menu_opacity=0
shadowless_popup=false
"""

os.makedirs(os.path.dirname(kvantum_cfg_path), exist_ok=True)
with open(kvantum_cfg_path, "w") as f:
    f.write(kvconfig)
print(f"Generated {kvantum_cfg_path}")

# Patch wallbash [GeneralColors] with current palette
wallbash_cfg = os.path.expanduser("~/.config/Kvantum/wallbash/wallbash.kvconfig")
if os.path.exists(wallbash_cfg):
    with open(wallbash_cfg) as f:
        content = f.read()

    import re
    new_colors = f"""[GeneralColors]
window.color={c['base']}
base.color={c['mantle']}
alt.base.color={c['mantle']}
button.color={c['surface1']}
light.color={c['surface2']}
mid.light.color={c['surface2']}
dark.color={c['surface0']}
mid.color={c['surface0']}
highlight.color={c['blue']}
inactive.highlight.color={c['blue']}
text.color={c['text']}
window.text.color={c['text']}
button.text.color={c['text']}
disabled.text.color={c['text']}
tooltip.text.color={c['text']}
highlight.text.color={c['base']}
link.color={c['blue']}
link.visited.color={c['mauve']}"""

    content = re.sub(
        r'\[GeneralColors\].*?(?=\n\[|\Z)',
        new_colors + '\n',
        content,
        flags=re.DOTALL
    )
    with open(wallbash_cfg, "w") as f:
        f.write(content)
    print(f"Patched {wallbash_cfg}")

    # Patch wallbash SVG — always from .template to avoid double-replacement
    wallbash_svg      = os.path.expanduser("~/.config/Kvantum/wallbash/wallbash.svg")
    wallbash_template = wallbash_svg + ".template"
    src = wallbash_template if os.path.exists(wallbash_template) else wallbash_svg
    with open(src) as f:
        svg = f.read()
    svg_replacements = [
        ('#1E1E2E', c['base']),
        ('#181825', c['mantle']),
        ('#313244', c['surface1']),
        ('#45475A', c['surface2']),
        ('#585B70', c['text']),   # was subtext1 — force bright text
        ('#CDD6F4', c['text']),
        ('#F5E0DC', c['blue']),
        ('#89B4FA', c['blue']),
        ('#F38BA8', c['red']),
        ('#CBA6F7', c['mauve']),
    ]
    for old, new in svg_replacements:
        svg = re.sub(re.escape(old), new, svg, flags=re.IGNORECASE)
    with open(wallbash_svg, "w") as f:
        f.write(svg)
    print(f"Patched SVG {wallbash_svg}")

    # Enable transparency in wallbash kvconfig (do after patching colors)
    with open(wallbash_cfg) as f:
        kv = f.read()
    kv = kv.replace('translucent_windows=false', 'translucent_windows=true')
    kv = re.sub(r'reduce_window_opacity=\d+', 'reduce_window_opacity=0', kv)
    with open(wallbash_cfg, "w") as f:
        f.write(kv)

# Notify KDE apps (Dolphin etc.) to reload colors
import subprocess
subprocess.run([
    'dbus-send', '--session', '--dest=org.kde.KGlobalSettings',
    '/KGlobalSettings', 'org.kde.KGlobalSettings.notifyChange',
    'int32:0', 'int32:0'
], capture_output=True)

# KDE kdeglobals color sections (Dolphin and other KDE apps read from here)
kdeglobals_path = os.path.expanduser("~/.config/kdeglobals")
with open(kdeglobals_path) as f:
    kdeglobals = f.read()

def kde_colors_block():
    bg      = c['base']
    bg_alt  = c['mantle']
    bg_view = c['mantle']
    btn     = c['surface1']
    fg      = c['text']
    fg_in   = c['text']        # same as normal — full white text everywhere
    fg_link = c['blue']
    accent  = c['blue']
    sel_bg  = c['blue']
    sel_fg  = c['base']
    tooltip_bg = c['surface1']

    return f"""
[Colors:Button]
BackgroundAlternate={bg_alt}
BackgroundNormal={btn}
DecorationFocus={accent}
DecorationHover={accent}
ForegroundActive={accent}
ForegroundInactive={fg_in}
ForegroundLink={fg_link}
ForegroundNormal={fg}
ForegroundNegative={c['red']}
ForegroundPositive={c['green']}
ForegroundVisited={c['mauve']}

[Colors:Selection]
BackgroundAlternate={sel_bg}
BackgroundNormal={sel_bg}
DecorationFocus={accent}
DecorationHover={accent}
ForegroundActive={sel_fg}
ForegroundInactive={sel_fg}
ForegroundLink={sel_fg}
ForegroundNormal={sel_fg}
ForegroundNegative={c['red']}
ForegroundPositive={c['green']}
ForegroundVisited={sel_fg}

[Colors:Tooltip]
BackgroundAlternate={tooltip_bg}
BackgroundNormal={tooltip_bg}
DecorationFocus={accent}
DecorationHover={accent}
ForegroundActive={fg}
ForegroundInactive={fg_in}
ForegroundLink={fg_link}
ForegroundNormal={fg}
ForegroundNegative={c['red']}
ForegroundPositive={c['green']}
ForegroundVisited={c['mauve']}

[Colors:View]
BackgroundAlternate={bg_alt}
BackgroundNormal={bg_view}
DecorationFocus={accent}
DecorationHover={accent}
ForegroundActive={accent}
ForegroundInactive={fg_in}
ForegroundLink={fg_link}
ForegroundNormal={fg}
ForegroundNegative={c['red']}
ForegroundPositive={c['green']}
ForegroundVisited={c['mauve']}

[Colors:Window]
BackgroundAlternate={c['surface0']}
BackgroundNormal={bg}
DecorationFocus={accent}
DecorationHover={accent}
ForegroundActive={accent}
ForegroundInactive={fg_in}
ForegroundLink={fg_link}
ForegroundNormal={fg}
ForegroundNegative={c['red']}
ForegroundPositive={c['green']}
ForegroundVisited={c['mauve']}

[Colors:Header]
BackgroundAlternate={c['surface0']}
BackgroundNormal={c['surface0']}
DecorationFocus={accent}
DecorationHover={accent}
ForegroundActive={accent}
ForegroundInactive={fg_in}
ForegroundLink={fg_link}
ForegroundNormal={fg}
ForegroundNegative={c['red']}
ForegroundPositive={c['green']}
ForegroundVisited={c['mauve']}

[Colors:Complementary]
BackgroundAlternate={c['surface1']}
BackgroundNormal={c['surface0']}
DecorationFocus={accent}
DecorationHover={accent}
ForegroundActive={accent}
ForegroundInactive={fg_in}
ForegroundLink={fg_link}
ForegroundNormal={fg}
ForegroundNegative={c['red']}
ForegroundPositive={c['green']}
ForegroundVisited={c['mauve']}

[ColorEffects:Disabled]
ChangeSelectionColor=true
Color={c['surface2']}
ColorAmount=0.55
ColorEffect=3
ContrastAmount=0.65
ContrastEffect=0
EnableIntensityEffect=false
IntensityAmount=0
IntensityEffect=0

[ColorEffects:Inactive]
ChangeSelectionColor=false
EnableIntensityEffect=false
"""

import re as _re
# Remove any existing Colors: sections
kdeglobals_clean = _re.sub(r'\n\[Colors:[^\]]*\].*?(?=\n\[|\Z)', '', kdeglobals, flags=_re.DOTALL)
kdeglobals_clean = _re.sub(r'\n\[ColorEffects:[^\]]*\].*?(?=\n\[|\Z)', '', kdeglobals_clean, flags=_re.DOTALL)
kdeglobals_new = kdeglobals_clean.rstrip() + '\n' + kde_colors_block()

with open(kdeglobals_path, "w") as f:
    f.write(kdeglobals_new)
print(f"Updated {kdeglobals_path}")
