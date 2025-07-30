#!/bin/sh
set -e

# kanata
# https://github.com/jtroo/kanata/wiki/Avoid-using-sudo-on-Linux
GROUP_NAME="uinput"
if ! getent group "$GROUP_NAME" > /dev/null; then
  echo "Group '$GROUP_NAME' does not exist. Creating it now..."
  sudo groupadd "$GROUP_NAME"
  echo "Group '$GROUP_NAME' created successfully."
else
  echo "Group '$GROUP_NAME' already exists. Skipping creation."
fi

sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"
echo "✅ Added uinput group - kanata."
KANATA_RULES='/etc/udev/rules.d/99-input.rules'
sudo touch $KANATA_RULES
sudo echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee $KANATA_RULES
sudo modprobe uinput
# sudo systemctl --user enable kanata.service
# sudo systemctl --user start kanata.service

# {{ if eq .chezmoi.hostname "pc" }}
# {{ else if eq .chezmoi.hostname "laptop" }}
# {{ end }}

