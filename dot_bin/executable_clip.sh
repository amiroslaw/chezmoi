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

ydotool key 29:1 47:1 47:0 29:0
# shift+insert -  primary clipboard 
# ydotool key 42:1 110:1 110:0 42:0

# wtype $(wl-paste)
# ydotool click 0x02
# wl-paste | ydotool key 225:1 96:1 96:0 225:0
# wl-paste | ydotool type --file -
#


