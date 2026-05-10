#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CONSTANTS & ARGUMENTS
# -----------------------------------------------------------------------------
QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IPC_FILE="/tmp/qs_widget_state"

ACTION="$1"
TARGET="$2"

# -----------------------------------------------------------------------------
# FAST PATH: WORKSPACE SWITCHING
# -----------------------------------------------------------------------------
if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    WORKSPACE_NUM="$ACTION"
    echo "close" > "$IPC_FILE"

    CMD="workspace $WORKSPACE_NUM"
    [[ "$2" == "move" ]] && CMD="movetoworkspace $WORKSPACE_NUM"
    hyprctl --batch "dispatch $CMD" >/dev/null 2>&1
    exit 0
fi

# -----------------------------------------------------------------------------
# ZOMBIE WATCHDOG
# -----------------------------------------------------------------------------
MAIN_QML_PATH="$HOME/.config/hypr/scripts/quickshell/Main.qml"
ISLAND_QML_PATH="$HOME/.config/hypr/scripts/quickshell/DynamicIsland.qml"
LAUNCHER_QML_PATH="$HOME/.config/hypr/scripts/quickshell/AppLauncher.qml"
CLIPBOARD_QML_PATH="$HOME/.config/hypr/scripts/quickshell/ClipboardViewer.qml"

if ! pgrep -f "quickshell.*Main\.qml" >/dev/null; then
    quickshell -p "$MAIN_QML_PATH" >/dev/null 2>&1 &
    disown
fi

if ! pgrep -f "quickshell.*DynamicIsland\.qml" >/dev/null; then
    quickshell -p "$ISLAND_QML_PATH" >/dev/null 2>&1 &
    disown
fi

if ! pgrep -f "quickshell.*AppLauncher\.qml" >/dev/null; then
    quickshell -p "$LAUNCHER_QML_PATH" >/dev/null 2>&1 &
    disown
fi

if ! pgrep -f "quickshell.*ClipboardViewer\.qml" >/dev/null; then
    quickshell -p "$CLIPBOARD_QML_PATH" >/dev/null 2>&1 &
    disown
fi

# -----------------------------------------------------------------------------
# IPC ROUTING
# -----------------------------------------------------------------------------
if [[ "$ACTION" == "close" ]]; then
    echo "close" > "$IPC_FILE"
    exit 0
fi

if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    # Music: route through the DynamicIsland (expand/collapse the island itself)
    if [[ "$TARGET" == "music" ]]; then
        echo "toggle" > /tmp/qs_island_toggle
        exit 0
    fi

    # Launcher: toggle the Spotlight-style app launcher
    if [[ "$TARGET" == "launcher" ]]; then
        echo "toggle" > /tmp/qs_launcher
        exit 0
    fi

    # Clipboard: toggle the clipboard history viewer
    if [[ "$TARGET" == "clipboard" ]]; then
        echo "toggle" > /tmp/qs_clipboard
        exit 0
    fi

    # Notifications: open island on notifs page
    if [[ "$TARGET" == "notifications" ]]; then
        echo "notifs" > /tmp/qs_island_page
        exit 0
    fi

    echo "$TARGET" > "$IPC_FILE"
    exit 0
fi
