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
var custom_song_loop_offset = 0.0

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

func play(song : String, from_position := 0.0, custom_song_loop_offset := 0.0):
	
	# This is here because we don't ever want the Invincible star theme to go into our
	# previous songs list, because if it did then we wouldn't know what song to
	# play once it had finished.
	if ![special_songs].has(current_song):
		previous_song = current_song
	
	#print("Playing song. Custom song loop offset = " + str(custom_song_loop_offset))
	stop_all()
	
	if is_custom_song(song):
		_play_custom_song(song, custom_song_loop_offset)
		return
	
	# Try seeing if we have the song as a child node (Base game songs)
	if has_node(song):
		var s = get_node(song)
		if s != null:
			s.pitch_scale = 1
			s.bus = "Music"
			s.play(from_position)
			
			current_song = song
			current_song_node = s
	
	else:
		push_error("Error playing music track! Unrecognised song: " + song)

# Returns true if the song given is a file path to a custom song.
func is_custom_song(song : String):
	
	# If the song name is the same as a base game song, return false.
	if has_node(song): return false
	
	# Otherwise, check the file exists.
	var dir = Directory.new()
	if dir.file_exists(song):
		var song_extension = song.get_extension()
		if !song_extension: return false
		
		# Check the file is of a supported type. (WAV, OGG, MP3)
		song_extension = "." + song_extension
		if Global.accepted_music_file_types.has(song_extension):
			return true
	
	return false

func _play_custom_song(song_filepath : String, loop_offset := 0.0):
	stop_all()
	
	var stream = Global.get_audio_stream_from_audio_file(song_filepath, true, loop_offset)
	
	if !stream: return
	
	custom_song.set_stream(stream)
	custom_song.play()
	
	current_song = song_filepath
	current_song_node = custom_song
	
	custom_song_loop_offset = loop_offset

# Identical to play(), but continues playing a song if it is already playing rather than restarting it.
# I.e. running continue("Invincible") while the Invincible music is already playing will result in no change.
func continue(song : String, custom_song_loop_offset := 0.0):
	
	#print("Continuing song. Custom LOOP OFFSET = " + str(custom_song_loop_offset))
	if current_song != song:
		play(song, 0.0, custom_song_loop_offset)

func stop_all():
	current_song_node = null
	current_song = null
	for child in get_children():
		if child.get_class() == "AudioStreamPlayer":
			child.stop()

func _on_Invincible_finished():
	if current_song != "Invincible": return
	
	if !previous_song: return
	play(previous_song, custom_song_loop_offset)

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
	AudioServer.set_bus_effect_enabled(3, 2, enabled)
	AudioServer.set_bus_effect_enabled(4, 1, enabled)
	AudioServer.set_bus_effect_enabled(5, 0, enabled)
