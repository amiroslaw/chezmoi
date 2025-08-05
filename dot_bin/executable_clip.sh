#!/usr/bin/env bash
set -o pipefail

# items=$(cliphist list) $(cat $PRIVATE/rofi/snippet)
selection=$({ cliphist list; cat "$PRIVATE/rofi/snippet"; } | rofi -dmenu)

if decoded=$(echo "$selection" | cliphist decode); then
    echo "$decoded" | wl-copy
else
    echo "$selection" | awk '{print $2}' | wl-copy
fi
sleep 0.100
# wtype $(wl-paste)
notify-send 2
# ydotool key 225:1 96:1 96:0 225:0
wl-paste | ydotool type --file -
