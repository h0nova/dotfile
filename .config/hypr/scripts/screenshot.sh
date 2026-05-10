#!/usr/bin/env bash

# Directories
SAVE_DIR="$HOME/Pictures/Screenshots"
RECORD_DIR="$HOME/Videos"
CACHE_DIR="$HOME/.cache/qs_recording_state"
mkdir -p "$SAVE_DIR" "$RECORD_DIR" "$CACHE_DIR"

# ---------------------------------------------------------
# PAUSE / RESUME
# ---------------------------------------------------------
if [ "$1" = "--pause" ] && [ -f "$CACHE_DIR/wl_pid" ]; then
  WL_PID=$(cat "$CACHE_DIR/wl_pid")
  FF_PID=$(cat "$CACHE_DIR/ff_pid")
  kill -SIGSTOP "$WL_PID" 2>/dev/null
  [ -n "$FF_PID" ] && [ "$FF_PID" != "0" ] && kill -SIGSTOP "$FF_PID" 2>/dev/null
  touch "$CACHE_DIR/paused"
  exit 0
fi

if [ "$1" = "--resume" ] && [ -f "$CACHE_DIR/wl_pid" ]; then
  WL_PID=$(cat "$CACHE_DIR/wl_pid")
  FF_PID=$(cat "$CACHE_DIR/ff_pid")
  kill -SIGCONT "$WL_PID" 2>/dev/null
  [ -n "$FF_PID" ] && [ "$FF_PID" != "0" ] && kill -SIGCONT "$FF_PID" 2>/dev/null
  rm -f "$CACHE_DIR/paused"
  exit 0
fi

# ---------------------------------------------------------
# STOP PHASE: Stop recording and merge
# ---------------------------------------------------------
if [ -f "$CACHE_DIR/wl_pid" ]; then
  WL_PID=$(cat "$CACHE_DIR/wl_pid")
  FF_PID=$(cat "$CACHE_DIR/ff_pid")
  VID_TMP=$(cat "$CACHE_DIR/vid_tmp")
  AUD_TMP=$(cat "$CACHE_DIR/aud_tmp")
  FINAL_FILE=$(cat "$CACHE_DIR/final_file")

  notify-send -a "Screen Recorder" "Processing..." "Save video ..."

  # If recording is paused — resume first, otherwise SIGINT won't reach
  [ -f "$CACHE_DIR/paused" ] && kill -SIGCONT "$WL_PID" 2>/dev/null
  [ -f "$CACHE_DIR/paused" ] && [ "$FF_PID" != "0" ] && kill -SIGCONT "$FF_PID" 2>/dev/null

  # Gracefully stop processes
  kill -SIGINT $WL_PID 2>/dev/null
  [ "$FF_PID" != "0" ] && kill -SIGINT $FF_PID 2>/dev/null

  # Wait for recording to finish (important for file integrity)
  timeout 5 bash -c "while kill -0 $WL_PID 2>/dev/null; do sleep 0.2; done"
  [ "$FF_PID" != "0" ] && timeout 5 bash -c "while kill -0 $FF_PID 2>/dev/null; do sleep 0.2; done"

  if [ -s "$VID_TMP" ]; then
    if [ -s "$AUD_TMP" ]; then
      # Merge video (with system audio) and microphone track
      # Use amix to combine audio into one stream
      ffmpeg -nostdin -y \
        -i "$VID_TMP" -i "$AUD_TMP" \
        -filter_complex "[0:a][1:a]amix=inputs=2:duration=first[aout]" \
        -map 0:v -map "[aout]" -c:v copy -c:a aac -b:a 192k \
        "$FINAL_FILE" -loglevel error
    else
      mv "$VID_TMP" "$FINAL_FILE"
    fi

    if [ -f "$FINAL_FILE" ]; then
      notify-send -a "Screen Recorder" -i "video-x-generic" "⏺ Recording..." "File: $(basename "$FINAL_FILE")\nDir: $RECORD_DIR"
    fi
  else
    notify-send -a "Screen Recorder" "Error" "Record not save"
  fi

  # Cleanup
  rm -f "$VID_TMP" "$AUD_TMP"
  rm -f "$CACHE_DIR"/wl_pid "$CACHE_DIR"/ff_pid "$CACHE_DIR"/vid_tmp "$CACHE_DIR"/aud_tmp "$CACHE_DIR"/final_file "$CACHE_DIR"/start_time "$CACHE_DIR"/paused
  exit 0
fi

# ---------------------------------------------------------
# START PHASE
# ---------------------------------------------------------
time=$(date +'%Y-%m-%d-%H%M%S')
FILENAME="$SAVE_DIR/Screenshot_$time.png"
VID_FILENAME="$RECORD_DIR/Recording_$time.mp4"

# Default values
EDIT_MODE=false
FULL_MODE=false
RECORD_MODE=false
GEOMETRY=""
MIC_MUTE="false"
MIC_DEVICE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --edit)
    EDIT_MODE=true
    shift
    ;;
  --full)
    FULL_MODE=true
    shift
    ;;
  --record)
    RECORD_MODE=true
    shift
    ;;
  --geometry)
    GEOMETRY="$2"
    shift 2
    ;;
  --mic-mute)
    MIC_MUTE="$2"
    shift 2
    ;;
  --mic-dev)
    MIC_DEVICE="$2"
    shift 2
    ;;
  *) shift ;;
  esac
done

if [ "$FULL_MODE" = true ] || [ -n "$GEOMETRY" ]; then

  if [ "$RECORD_MODE" = true ]; then
    VID_TMP="$RECORD_DIR/.temp_vid_${time}.mp4"
    AUD_TMP="$RECORD_DIR/.temp_aud_${time}.m4a"

    # System audio setup
    DESK_SINK=$(pactl get-default-sink 2>/dev/null)
    DESK_DEV="${DESK_SINK}.monitor"

    # Microphone setup
    if [ -n "$MIC_DEVICE" ] && [ "$MIC_DEVICE" != "null" ]; then
      MIC_DEV="$MIC_DEVICE"
    else
      MIC_DEV=$(pactl get-default-source 2>/dev/null)
    fi

    # Build wl-screenrec arguments
    WL_ARGS=()
    [ "$FULL_MODE" = false ] && WL_ARGS+=(-g "$GEOMETRY")
    [ -n "$DESK_DEV" ] && WL_ARGS+=(--audio --audio-device "$DESK_DEV")
    WL_ARGS+=(-f "$VID_TMP")

    # Start screen recording
    wl-screenrec "${WL_ARGS[@]}" &
    WL_PID=$!

    # Start microphone recording via ffmpeg (separate)
    FF_PID="0"
    if [ "$MIC_MUTE" != "true" ] && [ -n "$MIC_DEV" ]; then
      ffmpeg -nostdin -y -f pulse -i "$MIC_DEV" \
        -c:a aac -b:a 192k "$AUD_TMP" >/dev/null 2>&1 &
      FF_PID=$!
    fi

    # Save state
    echo "$WL_PID" >"$CACHE_DIR/wl_pid"
    echo "$FF_PID" >"$CACHE_DIR/ff_pid"
    echo "$VID_TMP" >"$CACHE_DIR/vid_tmp"
    echo "$AUD_TMP" >"$CACHE_DIR/aud_tmp"
    echo "$VID_FILENAME" >"$CACHE_DIR/final_file"
    date +%s >"$CACHE_DIR/start_time"

    notify-send -a "Screen Recorder" "⏺ The recording has started" "Press the shortcut to stop recording."
    exit 0
  fi

  # Screenshot mode
  if [ "$EDIT_MODE" = true ]; then
    if [ -n "$GEOMETRY" ]; then
      grim -g "$GEOMETRY" - | GSK_RENDERER=gl satty --filename - --copy-command wl-copy --init-tool brush
    else
      grim - | GSK_RENDERER=gl satty --filename - --copy-command wl-copy --init-tool brush
    fi
  else
    if [ -n "$GEOMETRY" ]; then
      grim -g "$GEOMETRY" - | wl-copy
    else
      grim - | wl-copy
    fi
    notify-send -a "Screenshot" “Screenshot copied” “Screenshot copied to clipboard”
  fi
  exit 0
fi

# If run without parameters — open the interface (Overlay)
quickshell -p ~/.config/hypr/scripts/quickshell/ScreenshotOverlay.qml
