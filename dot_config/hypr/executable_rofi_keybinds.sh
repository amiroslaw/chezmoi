#!/bin/bash

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

# extract the keybinding from hyprland.conf
mapfile -t BINDINGS < <(grep -E '^bind\s*=' "$HYPR_CONF" | \
    sed -E 's/bind\s*=\s*//g' | \
    awk -F ', ' '{cmd=""; for (i=3; i<=NF; i++) cmd=cmd $i " ";
    print "<b>" $1 "</b> + <b>" $2 "</b> <i>" cmd "</i> <span color=\"gray\">cmd</span>"}')

CHOICE=$(printf '%s\n' "${BINDINGS[@]}" | rofi -dmenu -matching prefix -i -markup-rows -p "Hyprland Keybinds:")

# extract cmd from span <span color='gray'>cmd</span>
CMD=$(echo "$CHOICE" | sed -n 's/.*<span color='\''gray'\''>\(.*\)<\/span>.*/\1/p')

# execute it if first word is exec else use hyprctl dispatch
if [[ $CMD == exec* ]]; then
    eval "$CMD"
else
    hyprctl dispatch "$CMD"
fi

