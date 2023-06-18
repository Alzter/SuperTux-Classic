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

# REMOVE AROUND A MONTH AFTER MERGED. ONLY USE THE NEW FILE PATH
const CONTROLS_LEGACY_FILE = "user://options/controls.dat"
const CONTROLS_FILE = "user://options/ctrl.json"

const save_file_1 = SAVE_DIR + "file1/"
const save_file_2 = SAVE_DIR + "file2/"
const save_file_3 = SAVE_DIR + "file3/"
const save_file_4 = SAVE_DIR + "file4/"
const save_file_5 = SAVE_DIR + "file5/"

enum CONTROLS_FILE_TYPE {None,Legacy,Current}

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
		
		
		print("Loading Options Data:")
		print(options)
		print()
		
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
		
		print("Saved Options Data")
		print(optionsData)
		print()
	else:
		print("Error saving options data")
		push_error("Failure saving options file")
	
	yield(get_tree(), "idle_frame")

func does_options_data_exist() -> bool:
	var file = File.new()
	return file.file_exists(OPTIONS_FILE)

func does_control_data_exist() -> int:
	var file = File.new()
	if file.file_exists(CONTROLS_FILE):
		return CONTROLS_FILE_TYPE.Current
	elif file.file_exists(CONTROLS_LEGACY_FILE):
		return CONTROLS_FILE_TYPE.Legacy
	else:
		return CONTROLS_FILE_TYPE.None

func new_game(initial_level, worldmap_level = null):
	WorldmapManager.reset()
	Scoreboard.coins = Scoreboard.initial_coins
	Scoreboard.lives = Scoreboard.initial_lives
	Scoreboard.player_initial_state = Scoreboard.initial_state
	
	if worldmap_level:
		WorldmapManager.worldmap_level = worldmap_level
	
	Global.goto_level(initial_level)

func save_game(world : String = WorldmapManager.worldmap_name, levels_cleared : Array = WorldmapManager.cleared_levels, worldmap_level : String = WorldmapManager.worldmap_level, worldmap_position : Vector2 = WorldmapManager.worldmap_player_position, save_path : String = current_save_directory):
	save_path = save_path + world + ".dat"
	
	if !world:
		push_error("Error saving game: The current worldmap isn't inside a folder. The worldmap's folder name will become the name of the save file.")
		return
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
	if !dir.dir_exists(current_save_directory):
		dir.make_dir_recursive(current_save_directory)
	
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

func has_savefile(world = WorldmapManager.worldmap_name, dir_to_check = current_save_directory):
	if !world:
		push_error("Error checking for save file: No world to check specified!")
		return false
	
	var file = File.new()
	return file.file_exists(dir_to_check + world + ".dat")

func load_game(world = WorldmapManager.worldmap_name, load_path = current_save_directory):
	var file = File.new()
	var save_data = null
	
	if !world:
		push_error("Error loading save file: No world was specified to load!")
		return
	
	load_path = load_path + world + ".dat"
	
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
	var files_to_delete = Global.list_files_in_directory(current_save_directory)
	var dir = Directory.new()
	for file in files_to_delete:
		dir.remove(file)

func save_current_controls():
	print("Saving current player controls")
	
	var controls = {"Key": [], "Gamepad": []}
	for control in Global.controls:
		var input_list = InputMap.get_action_list(control)
		var input_key: InputEventKey = null
		var input_button: InputEventJoypadButton = null
		
		for i in input_list:
			if i is InputEventKey:
				input_key = i
			elif i is InputEventJoypadButton:
				input_button = i
		
		if input_key == null:
			push_error("Error saving controls: Cannot convert null InputEvent into a scancode because it is not of type InputEventKey")
			continue
		if input_button == null:
			push_error("Error saving controls: Cannot convert null InputEvent into a button_index because it is not of type InputEventJoypadButton")
			continue
		
		var scancode = input_key.get_scancode()
		controls["Key"].append(scancode)
		controls["Gamepad"].append(input_button.button_index)
	
	# Save this array of scancodes to the controls file.
	var file = File.new()
	var controls_file = file.open(CONTROLS_FILE, File.WRITE)
	if controls_file == OK:
		file.store_string(to_json(controls))
		file.close()
	else:
		push_error("Failure saving controls file")
	
	yield(get_tree(), "idle_frame")

func load_current_controls(load_path = CONTROLS_FILE):
	var file = File.new()
	var type_of_controls_file: int = does_control_data_exist()
	print_debug("Control File Type: %s" % CONTROLS_FILE_TYPE.keys()[type_of_controls_file])
	if type_of_controls_file != CONTROLS_FILE_TYPE.None:
		var load_state = file.open(load_path, file.READ)
		if load_state == OK:
			match type_of_controls_file:
				CONTROLS_FILE_TYPE.Current:
					var controls: Dictionary = parse_json(file.get_line())
					_deencapsulate_player_controls(controls)
				CONTROLS_FILE_TYPE.Legacy:
					var controls: Array = file.get_var()
					_deencapsulate_player_controls_legacy(controls)
					
					# Remove old file and save to new file
					var dir = Directory.new()
					dir.open(OPTIONS_DIR)
					dir.remove(CONTROLS_LEGACY_FILE)
					save_current_controls()
				_:
					printerr("WHAT DID YOU DO")
			file.close()
	else:
		print("No controls data exists. The default controls data will be used.")

func _deencapsulate_player_controls(controls: Dictionary):
	print("Loading saved player controls")
	for i in range(len(controls["Key"])):
		var control_action = Global.controls[i]
		var ctrl_list = InputMap.get_action_list(control_action)
		var inputeventkey = InputEventKey.new()
		inputeventkey.scancode = controls["Key"][i]
		var inputeventpad = InputEventJoypadButton.new()
		inputeventpad.button_index = controls["Gamepad"][i]
		
		var del_inev_key: InputEventKey = null
		var del_inev_pad: InputEventJoypadButton = null
		
		for event_id in range(2):
			var tmp_inev = ctrl_list[event_id]
			if tmp_inev is InputEventKey:
				del_inev_key = tmp_inev
			elif tmp_inev is InputEventJoypadButton:
				del_inev_pad = tmp_inev
		
		if del_inev_key != null:
			InputMap.action_erase_event(control_action, del_inev_key)
			InputMap.action_add_event(control_action, inputeventkey)
			
		if del_inev_pad != null:
			InputMap.action_erase_event(control_action, del_inev_pad)
			InputMap.action_add_event(control_action, inputeventpad)

	# Make the controls set for moving Tux also be used to navigate the UI
	var ui_actions = [
		["ui_left", "move_left"],
		["ui_right", "move_right"],
		["ui_up", "move_up"],
		["ui_down", "duck"]]

	for action in ui_actions:
		var ui_action = action[0]
		var move_action = action[1]

		var ctrl_list = InputMap.get_action_list(ui_action)

		var del_inev_key: InputEventKey = null
		var del_inev_pad: InputEventJoypadButton = null

		for tmp_inev in ctrl_list:
			if tmp_inev is InputEventKey:
				del_inev_key = tmp_inev
			elif tmp_inev is InputEventJoypadButton:
				del_inev_pad = tmp_inev

		if del_inev_key != null:
			InputMap.action_erase_event(ui_action, del_inev_key)

		if del_inev_pad != null:
			InputMap.action_erase_event(ui_action, del_inev_pad)

		var inputs = InputMap.get_action_list(move_action)

		for input in inputs:
			if input is InputEventKey or input is InputEventJoypadButton:
				InputMap.action_add_event(ui_action, input)

# NOTE: this is for the legacy controls file. This will not contain InputEventJoypadButtons!
# De-encapsulates the player controls from an array of scancodes into InputEventKeys
# and assigns those to the relevant actions.
func _deencapsulate_player_controls_legacy(scancode_array : Array):
	print("Loading saved player controls (LEGACY)")
	var i = 0
	for scancode in scancode_array:
		var control_action = Global.controls[i]
		var ctrl_list = InputMap.get_action_list(control_action)
		var inputeventkey = InputEventKey.new()
		inputeventkey.scancode = scancode
		
		var del_inev: InputEvent = null
		
		for tmp_inev in ctrl_list:
			if tmp_inev is InputEventKey:
				del_inev = tmp_inev
				break
		
		if del_inev != null:
			InputMap.action_erase_event(control_action, del_inev)
			InputMap.action_add_event(control_action, inputeventkey)
		
		i += 1
	
	# Make the controls set for moving Tux also be used to navigate the UI
	
	var ui_actions = [
		["ui_left", "move_left"],
		["ui_right", "move_right"],
		["ui_up", "move_up"],
		["ui_down", "duck"]]
	
	for action in ui_actions:
		var ui_action = action[0]
		var move_action = action[1]
		
		var ctrl_list = InputMap.get_action_list(ui_action)
		
		var del_inev: InputEvent = null
		
		for event_id in range(2):
			var tmp_inev = ctrl_list[event_id]
			if tmp_inev is InputEventKey:
				del_inev = tmp_inev
				break
		
		if del_inev != null:
			InputMap.action_erase_event(ui_action, del_inev)
		
			var inputs = InputMap.get_action_list(move_action)
			
			for input in inputs:
				if input is InputEventKey:
					InputMap.action_add_event(ui_action, input)

func _list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files

# Old versions of SuperTux Classic (0.2.0 and below) stored save-files in a different directory
# to the current version. These methods transfer the save-files made in STC 0.2.0 to the new directory
# used in STC 0.3.0 and above.

func has_old_savefile():
	var old_save_file = SAVE_DIR + "file1.dat"
	var file = File.new()
	return file.file_exists(old_save_file)

func transfer_old_savefile_to_new_save_path():
	if !has_old_savefile():
		push_error("No old save file exists to transfer!")
		return
	
	var old_save_file_path = SAVE_DIR + "file1.dat"
	var new_save_file_path = current_save_directory + "world1.dat"
	
	var dir = Directory.new()
	
	if !dir.dir_exists(current_save_directory):
		dir.make_dir_recursive(current_save_directory)
	
	var save_transfer_status = dir.copy(old_save_file_path, new_save_file_path)
	
	if save_transfer_status == OK:
		dir.remove(old_save_file_path)
	else:
		print("Error transferring old SuperTux Classic save file from path " + old_save_file_path + " to path " + new_save_file_path)
		print("Error code: " + str(save_transfer_status))

func load_world(world_name : String, initial_level_of_world : String):
	if has_savefile(world_name):
		load_game(world_name)
	else:
		new_game(initial_level_of_world)
