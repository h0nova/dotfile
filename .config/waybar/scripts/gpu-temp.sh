#!/usr/bin/env bash
# GPU temperature — NVIDIA GTX 1050 Max-Q (Optimus)
# Shows temp when GPU is active, "---" when in power-save mode

temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null \
    | grep -E '^[0-9]+$' | head -1)

if [[ -n "$temp" ]]; then
    echo "󰾲 ${temp}°"
else
    echo "󰾲 ---"
fi
