#!/bin/sh
set -e

mkdir -p "$HOME"/Documents "$HOME"/Downloads "$HOME"/Pictures "$HOME"/Videos

# {{ if eq .chezmoi.hostname "pc" }}
# {{ else if eq .chezmoi.hostname "laptop" }}
# {{ end }}

