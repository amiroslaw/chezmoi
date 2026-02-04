#!/bin/bash
# TODO grab path from mpd config
library=/media/multimedia/Musics/

song_name=$(rmpc song | fx '.file')
	#Delete the song
print "$library$song_name"
gomi "$library$song_name"
#Remove the song from playlist
#Write to log file
notify-send "[`date`] -> $song_name deleted."
# rmpc can't delete a song from a playlist
rmpc update
# playlist_pos=$(mpc -f %position% current)
# mpc del $playlist_pos
