#!/bin/bash
ASSETS="$HOME/.config/fastfetch/assets"
random=$(ls "$ASSETS"/*.png | grep -v current.png | shuf -n1)
ln -sf "$random" "$ASSETS/current.png"
fastfetch
