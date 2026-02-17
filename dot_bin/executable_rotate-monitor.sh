#!/bin/bash

MON="DVI-I-1"
CURRENT=$(hyprctl monitors -j | fx ".find(m => m.name === \"$MON\").transform")

if [ "$CURRENT" = "1" ]; then
    # Switch to normal
    hyprctl keyword monitor "$MON,1920x1080@60.0,1920x0,1.0"
else
    # Switch to rotated
    hyprctl keyword monitor "$MON,1920x1080@60.0,1920x0,1.0,transform,1"
fi
