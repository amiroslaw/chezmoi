#!/bin/sh
set +e
sudo zypper install -y zsh

chsh -s $(which zsh)
mkdir -p "$HOME"/Documents "$HOME"/Downloads "$HOME"/Pictures "$HOME"/Videos

# packman
sudo zypper addrepo -cfp 90 'http://ftp.fau.de/packman/suse/openSUSE_Tumbleweed/' packman
sudo zypper ref
sudo zypper dup --from packman --allow-vendor-change


# {{ if eq .chezmoi.hostname "pc" }}
# {{ else if eq .chezmoi.hostname "laptop" }}
# {{ end }}

