#!/bin/bash
taskrc="$HOME/.config/task/taskrc"
echo "include $HOME/Documents/Ustawienia/private/task/inthe/inthe-config" >> "$taskrc"
task sync
sed -i '$,$ d' "$taskrc"
