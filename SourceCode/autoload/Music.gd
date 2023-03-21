#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2022 Alexander Small <alexsmudgy20@gmail.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


extends CanvasLayer

var previous_song = null
var current_song = null
var current_song_node = null

var special_songs = [
	"Invincible"
]

func play(song, keep_other_songs = false):
	if !keep_other_songs: stop_all()
	if has_node(song):
		var s = get_node(song)
		if s != null:
			s.pitch_scale = 1
			s.bus = "Music"
			s.play()
			
			# This is here because we don't ever want the Invincible star theme to go into our
			# previous songs list, because if it did then we wouldn't know what song to
			# play once it had finished.
			if ![special_songs].has(current_song):
				previous_song = current_song
			
			current_song = song
			current_song_node = s

# Identical to play(), but continues playing a song if it is already playing rather than restarting it.
# I.e. running continue("Invincible") while the Invincible music is already playing will result in no change.
func continue(song):
	if current_song != song:
		play(song)

func stop_all():
	current_song_node = null
	for child in get_children():
		if child.get_class() == "AudioStreamPlayer":
			child.stop()

func _on_Invincible_finished():
	if current_song != "Invincible": return
	play(previous_song)

func speed_up():
	if current_song_node != null:
		current_song_node.pitch_scale = 1.25
