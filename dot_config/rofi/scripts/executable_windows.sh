#!/bin/sh
# windows switcher for hyprland
WINDOW=$(hyprctl clients | grep "class: " | awk '{gsub("class: ", ""); print}' | awk '{$1=$1};1' | rofi -dmenu -p "Window")
hyprctl dispatch focuswindow class:"$WINDOW"
