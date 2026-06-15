#!/usr/bin/env bash
path="$1"
name="${filename##*/}"
name="${name%.*}"     
newname=$(yad --entry --text="rename" --entry-text="$name")
dirname="${path%/*}"             
ext="${path##*.}"               
newpath="$dirname/$newname.$ext"
echo  $path $newpath
mv  "$path" "$newpath"

notify-send $newpath

# path="/home/user/music/playlist.txt"; echo "$path" | sed -E "s/[^/]+(\.[^./]+)$/$(yad --entry --title="Enter new name")\1/"
