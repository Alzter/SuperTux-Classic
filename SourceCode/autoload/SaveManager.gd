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


func new_game():
	Scoreboard.coins = Scoreboard.initial_coins
	Scoreboard.lives = Scoreboard.initial_lives
	Scoreboard.player_initial_state = Scoreboard.initial_state
	
	Global.goto_level(LevelRoster.first_level)

func save_game(level_reached, save_path = current_save_directory):
	var save_data = _encapsulate_game_data(level_reached)
	
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

func _encapsulate_game_data(level_reached):
	var level = level_reached
	var coins = Scoreboard.coins
	var lives = Scoreboard.lives
	var player_state = Scoreboard.player_initial_state
	
	var save_data = {
		"level" : level,
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
		print("Error loading SuperTux save file at path: " + str(load_path))
	
	yield(get_tree(), "idle_frame")

func _decapsulate_game_data(data_dictionary):
	var level = data_dictionary.get("level")
	var coins = data_dictionary.get("coins")
	var lives = data_dictionary.get("lives")
	var player_state = data_dictionary.get("player_state")
	
	Scoreboard.coins = coins
	Scoreboard.lives = lives
	Scoreboard.player_initial_state = player_state
	Global.goto_level(level)

func delete_save_file(save_path = current_save_directory):
	var dir = Directory.new()
	dir.remove(save_path)
