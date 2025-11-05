#!/usr/bin/env bash
# Set wallpaper on all connected monitors using mpvpaper

WALLPAPER="$HOME/nix-flake/assets/wallpaper.mp4"

# Kill existing mpvpaper instances
pkill -9 mpvpaper 2>/dev/null

# Get all connected monitors from Hyprland
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')

# Start mpvpaper for each monitor
for monitor in $MONITORS; do
    mpvpaper -o 'no-audio loop' "$monitor" "$WALLPAPER" &
done
