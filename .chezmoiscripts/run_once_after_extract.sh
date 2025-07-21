#!/bin/bash
set -e

FONT_ARCH="$HOME/Documents/Ustawienia/configs/fonts/"
FONT_DIR="$HOME/.local/share/fonts/"
cd "$FONT_ARCH"
mkdir -p "$FONT_DIR"
7z e nerd-fonts.7z -o"$FONT_DIR"
7z e MS.7z -o"$FONT_DIR"
7z x monaspace.7z -o"$FONT_DIR"

echo "✅ Extract fonts completed"

# vi: ft=bash

