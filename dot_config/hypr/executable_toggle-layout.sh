#!/bin/bash

current_layout=$(hyprctl getoption general:layout | grep -oE '(master|dwindle)')

if [ "$current_layout" = "master" ]; then
	  hyprctl keyword general:layout dwindle
  else
	    hyprctl keyword general:layout master
fi


