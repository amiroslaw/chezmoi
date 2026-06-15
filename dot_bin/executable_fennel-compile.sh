#!/bin/bash
notify-send 'compile fennel started'
chezmoi apply --force ~/.config/swayimg
LUA=luajit fennel --compile ~/.config/swayimg/init.fnl > ~/.config/swayimg/init.lua
rm ~/.config/swayimg/*.fnl
# LUA=luajit fennel --compile ~/.local/chezmoi/dot_config/swayimg/init.fnl > ~/.config/swayimg/init.lua

chezmoi apply --force ~/.config/hypr
LUA=luajit fennel --compile ~/.config/hypr/util.fnl > ~/.config/hypr/util.lua
LUA=luajit fennel --compile ~/.config/hypr/hyprland.fnl > ~/.config/hypr/hyprland.lua
LUA=luajit fennel --compile ~/.config/hypr/monitor.fnl > ~/.config/hypr/monitor.lua
LUA=luajit fennel --compile ~/.config/hypr/look.fnl > ~/.config/hypr/look.lua
LUA=luajit fennel --compile ~/.config/hypr/rules.fnl > ~/.config/hypr/rules.lua
rm ~/.config/hypr/*.fnl

notify-send 'compile fennel finished'

hyprctl reload
