#!/bin/bash

MON="DVI-I-1"
CURRENT=$(hyprctl monitors -j | fx ".find(m => m.name === \"$MON\").transform")
echo $CURRENT
if [ "$CURRENT" = "1" ]; then
    # Switch to normal
	hyprctl eval "hl.monitor({ output = '$MON', mode = '1920x1080@60.0', position = '1920x0', scale = 1.0 })"
else
    # Switch to rotated
	hyprctl eval "hl.monitor({ output = 'desc:$MON', mode = '1920x1080@60', position = '1920x0', scale = 1.0, transform = 1 })"
	hyprctl reload
fi
