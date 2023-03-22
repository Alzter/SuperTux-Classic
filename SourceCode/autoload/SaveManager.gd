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


extends Node

const SAVE_DIR = "user://savefiles/"
const OPTIONS_DIR = "user://options/"
const OPTIONS_FILE = "user://options/options.dat"
const CONTROLS_FILE = "user://options/controls.dat"

const save_file_1 = SAVE_DIR + "file1.dat"
const save_file_2 = SAVE_DIR + "file2.dat"
const save_file_3 = SAVE_DIR + "file3.dat"
const save_file_4 = SAVE_DIR + "file4.dat"
const save_file_5 = SAVE_DIR + "file5.dat"

var current_save_directory = save_file_1

signal save_completed
signal load_completed

# Returns the saved options data as a Dictionary
func get_options_data() -> Dictionary:
	var file = File.new()
	if !file.file_exists(OPTIONS_FILE):
		push_error("Options Data does not exist")
		return {} # Return empty dictionary
	
	var options_file = file.open(OPTIONS_FILE, File.READ)
	if options_file == OK:
		var options : Dictionary = file.get_var()
		file.close()
		return options
	else:
		push_error("Error reading options file")
		return {}

# Saves a Dictionary of game options to a file for later access.
func save_options_data(optionsData : Dictionary):
	var dir = Directory.new()
	if !dir.dir_exists(OPTIONS_DIR):
		dir.make_dir_recursive(OPTIONS_DIR)
	
	var file = File.new()
	var options_file = file.open(OPTIONS_FILE, File.WRITE)
	if options_file == OK:
		file.store_var(optionsData)
		file.close()
	else:
		push_error("Failure saving options file")
	
	yield(get_tree(), "idle_frame")

func does_options_data_exist() -> bool:
	var file = File.new()
	return file.file_exists(OPTIONS_FILE)

func new_game(initial_level, worldmap_level = null):
	WorldmapManager.reset()
	Scoreboard.coins = Scoreboard.initial_coins
	Scoreboard.lives = Scoreboard.initial_lives
	Scoreboard.player_initial_state = Scoreboard.initial_state
	
	if worldmap_level != null:
		WorldmapManager.worldmap_level = worldmap_level
	
	Global.goto_level(initial_level)

func save_game(levels_cleared : Array = WorldmapManager.cleared_levels, worldmap_level : String = WorldmapManager.worldmap_level, worldmap_position : Vector2 = WorldmapManager.worldmap_player_position, save_path : String = current_save_directory):
	if worldmap_level == null:
		push_error("Error saving game: there is no worldmap level for the player to return to")
		return
	if worldmap_position == null:
		push_error("Error saving game: player has no position in the worldmap")
		return
	if save_path == null:
		push_error("Error saving game: No save path specified")
	
	var save_data = _encapsulate_game_data(levels_cleared, worldmap_level, worldmap_position)
	
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
	
	var file = File.new()
	var save_state = file.open(save_path, file.WRITE)
	
	if save_state == OK:
		file.store_var(save_data)
		file.close()
	else:
		print("Error creating SuperTux save file at path: " + str(save_path))
		print("Error code: " + str(save_state))
	
	yield(get_tree(), "idle_frame")
	emit_signal("save_completed")

func _encapsulate_game_data(levels_cleared : Array, worldmap_level : String, worldmap_position : Vector2):
	var coins = Scoreboard.coins
	var lives = Scoreboard.lives
	var player_state = Scoreboard.player_initial_state
	
	var save_data = {
		"levels_cleared" : levels_cleared,
		"worldmap_level" : worldmap_level,
		"worldmap_x" : worldmap_position.x,
		"worldmap_y" : worldmap_position.y,
		"coins" : coins,
		"lives" : lives,
		"player_state" : player_state
	}
	
	return save_data

func has_savefile(dir_to_check = current_save_directory):
	var file = File.new()
	return file.file_exists(dir_to_check)

func load_game(load_path = current_save_directory):
	var file = File.new()
	var save_data = null
	if file.file_exists(load_path):
		var load_state = file.open(load_path, file.READ)
		
		if load_state == OK:
			save_data = file.get_var()
			file.close()
			
			_decapsulate_game_data(save_data)
	
	if save_data == null:
		push_error("Error loading SuperTux save file at path: " + str(load_path))
	
	yield(get_tree(), "idle_frame")

func _decapsulate_game_data(data_dictionary):
	var levels_cleared = data_dictionary.get("levels_cleared")
	var worldmap_level = data_dictionary.get("worldmap_level")
	var worldmap_x = data_dictionary.get("worldmap_x")
	var worldmap_y = data_dictionary.get("worldmap_y")
	var worldmap_position = Vector2(worldmap_x, worldmap_y)
	var coins = data_dictionary.get("coins")
	var lives = data_dictionary.get("lives")
	var player_state = data_dictionary.get("player_state")
	
	Scoreboard.coins = coins
	Scoreboard.lives = lives
	Scoreboard.player_initial_state = player_state
	WorldmapManager.worldmap_level = worldmap_level
	WorldmapManager.cleared_levels = levels_cleared
	WorldmapManager.worldmap_player_position = worldmap_position
	
	Global.goto_level(worldmap_level)

func delete_save_file(save_path = current_save_directory):
	var dir = Directory.new()
	dir.remove(save_path)

func save_current_controls():
	print("Saving current player controls")
	
	# ENCAPSULATION:
	# Store the list of controls as scancodes in an array.
	var controls = []
	for control in Global.controls:
		var input : InputEventKey = InputMap.get_action_list(control)[0]
		
		if not input is InputEventKey:
			push_error("Error saving controls: Cannot convert InputEvent " + input.as_text() + " into a scancode because it is not of type InputEventKey")
		
		var scancode = input.get_scancode()
		controls.append(scancode)
	
	# Save this array of scancodes to the controls file.
	var file = File.new()
	var controls_file = file.open(CONTROLS_FILE, File.WRITE)
	if controls_file == OK:
		file.store_var(controls)
		file.close()
	else:
		push_error("Failure saving controls file")
	
	yield(get_tree(), "idle_frame")


func load_current_controls(load_path = CONTROLS_FILE):
	var file = File.new()
	var controls = null
	if file.file_exists(load_path):
		var load_state = file.open(load_path, file.READ)
		
		if load_state == OK:
			controls = file.get_var()
			file.close()
			
			_deencapsulate_player_controls(controls)

# De-encapsulates the player controls from an array of scancodes into InputEventKeys
# and assigns those to the relevant actions.
func _deencapsulate_player_controls(scancode_array : Array):
	print("Loading saved player controls")
	var i = 0
	for scancode in scancode_array:
		var control_action = Global.controls[i]
		var inputeventkey = InputEventKey.new()
		inputeventkey.scancode = scancode
		
		InputMap.action_erase_events(control_action)
		InputMap.action_add_event(control_action, inputeventkey)
		
		i += 1
