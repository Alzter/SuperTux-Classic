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

var songs = []

onready var tween = $Tween
onready var custom_song = $Custom

func _ready():
	set_editor_music(false)
	
	for song in get_children():
		if song == custom_song: continue
		if song is AudioStreamPlayer:
			songs.append(song.name)

var special_songs = [
	"Invincible"
]

func play(song, keep_other_songs = false, from_position = 0.0):
	if !keep_other_songs: stop_all()
	
	# Try seeing if we have the song as a child node (Base game songs)
	if has_node(song):
		var s = get_node(song)
		if s != null:
			s.pitch_scale = 1
			s.bus = "Music"
			s.play(from_position)
			
			# This is here because we don't ever want the Invincible star theme to go into our
			# previous songs list, because if it did then we wouldn't know what song to
			# play once it had finished.
			if ![special_songs].has(current_song):
				previous_song = current_song
			
			current_song = song
			current_song_node = s
	
	# If that doesn't work, try playing the song as a custom song
	else:
		
		if !play_custom_song(song) == OK:
			push_error("Error playing music track! Unrecognised song: " + song)

func play_custom_song(song_filepath : String):
	var f = File.new()
	
	if f.file_exists(song_filepath) and song_filepath.ends_with(".mp3"):
		
		f.open(song_filepath, f.READ)
		
		var buffer = f.get_buffer(f.get_len())
		
		f.close()
		
		if !buffer: return ERR_BUG
		
		var stream = AudioStreamMP3.new()
		stream.set_data(buffer)
		stream.set_loop(true)
		
		custom_song.set_stream(stream)
		custom_song.play()
		
		current_song = song_filepath
		current_song_node = custom_song
	
		return OK
	
	return ERR_FILE_NOT_FOUND

# Identical to play(), but continues playing a song if it is already playing rather than restarting it.
# I.e. running continue("Invincible") while the Invincible music is already playing will result in no change.
func continue(song):
	if current_song != song:
		play(song)

func stop_all():
	current_song_node = null
	current_song = null
	for child in get_children():
		if child.get_class() == "AudioStreamPlayer":
			child.stop()

func _on_Invincible_finished():
	if current_song != "Invincible": return
	play(previous_song)

func speed_up():
	if current_song_node != null:
		current_song_node.pitch_scale = 1.25

func pitch_slide_down():
	if current_song_node != null:
		tween.stop_all()
		tween.interpolate_property(current_song_node, "pitch_scale", 1, 0.1, 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()

func pitch_slide_up():
	if current_song_node != null:
		tween.stop_all()
		tween.interpolate_property(current_song_node, "pitch_scale", 0.1, 1, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()

# If true, applies filters to the music. Used for Edit Mode in the level editor.
func set_editor_music(enabled : bool):
	AudioServer.set_bus_bypass_effects(2, !enabled)
