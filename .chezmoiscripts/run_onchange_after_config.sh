#!/bin/sh
set -e

pueue group add mpv-audio && pueue group add dl-video && pueue group add dl-audio && pueue group add mpv-fullscreen && pueue group add mpv-popup && pueue group add wget
pueue parallel -g default 9 && pueue parallel -g dl-video 9 && pueue parallel -g dl-audio 9 

mkdir -p  $HOME/Videos/YouTube/ $HOME/Downloads/wget $HOME/Musics/PODCASTS/ $HOME/Pictures/gallery-dl/

# {{ if eq .chezmoi.hostname "pc" }}
# {{ else if eq .chezmoi.hostname "laptop" }}
# {{ end }}

