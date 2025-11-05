#!/usr/bin/env bash
# Screenshot script for Hyprland using grim and slurp

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FILENAME="$SCREENSHOT_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

case "$1" in
  full)
    # Full screen screenshot
    grim "$FILENAME" && \
      wl-copy < "$FILENAME" && \
      notify-send "Screenshot" "Full screen captured and copied to clipboard" -i camera-photo
    ;;
  area)
    # Area selection screenshot
    grim -g "$(slurp)" "$FILENAME" && \
      wl-copy < "$FILENAME" && \
      notify-send "Screenshot" "Area captured and copied to clipboard" -i camera-photo
    ;;
  window)
    # Active window screenshot
    WINDOW_GEOMETRY=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    grim -g "$WINDOW_GEOMETRY" "$FILENAME" && \
      wl-copy < "$FILENAME" && \
      notify-send "Screenshot" "Window captured and copied to clipboard" -i camera-photo
    ;;
  *)
    echo "Usage: $0 {full|area|window}"
    exit 1
    ;;
esac
