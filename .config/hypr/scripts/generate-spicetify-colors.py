#!/usr/bin/env python3
import json, subprocess, sys
from pathlib import Path

QS_COLORS = Path.home() / ".config/hypr/scripts/quickshell/qs_colors.json"
COLOR_INI  = Path.home() / ".config/spicetify/Themes/Comfy/color.ini"

with open(QS_COLORS) as f:
    c = json.load(f)

def h(key):
    return c[key].lstrip("#")

ini = f"""\
[Dynamic]
text               = {h("text")}
subtext            = {h("subtext0")}
main               = {h("base")}
main-elevated      = {h("surface0")}
main-transition    = {h("mantle")}
highlight          = {h("surface1")}
highlight-elevated = {h("surface2")}
sidebar            = {h("mantle")}
player             = {h("crust")}
card               = {h("surface0")}
shadow             = {h("crust")}
selected-row       = {h("text")}
button             = {h("blue")}
button-active      = {h("mauve")}
button-disabled    = {h("surface2")}
tab-active         = {h("surface0")}
notification       = {h("green")}
notification-error = {h("red")}
misc               = {h("mauve")}
play-button        = {h("blue")}
play-button-active = {h("mauve")}
progress-fg        = {h("blue")}
progress-bg        = {h("surface1")}
heart              = {h("red")}
pagelink-active    = {h("blue")}
radio-btn-active   = {h("blue")}
"""

COLOR_INI.parent.mkdir(parents=True, exist_ok=True)

# keep existing schemes, append/replace Dynamic section
existing = COLOR_INI.read_text() if COLOR_INI.exists() else ""
lines = existing.splitlines()
# remove old [Dynamic] block if present
out, skip = [], False
for line in lines:
    if line.strip() == "[Dynamic]":
        skip = True
    elif skip and line.startswith("["):
        skip = False
    if not skip:
        out.append(line)
base_ini = "\n".join(out).rstrip() + "\n\n" if out else ""
COLOR_INI.write_text(base_ini + ini)
print("Comfy color.ini written")

subprocess.run(["spicetify", "config", "current_theme", "Comfy", "color_scheme", "Dynamic"], check=True)
result = subprocess.run(["spicetify", "apply"], capture_output=True, text=True)
if result.returncode == 0:
    print("Spicetify applied")
else:
    print("Spicetify apply error:", result.stderr[-300:], file=sys.stderr)
    sys.exit(1)
