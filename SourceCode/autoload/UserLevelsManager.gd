extends Node

const user_worlds_directory = "user://addon_worlds/"
const user_worlds_folder = "addon_worlds/"
const world_data_file = "world.data"
const worldmap_file = "worldmap.tscn"

var default_level_template = "res://scenes/leveleditor/level_templates/level.tscn"
var default_worldmap_level = "res://scenes/leveleditor/level_templates/worldmap.tscn"

var user_worlds: Dictionary = {}

var current_world = null
var current_level = null

# If true, the target device supports opening folders and modifying files for user worlds.
var custom_content_supported = null setget , _is_custom_content_supported

func reload_user_worlds():
	unload_user_worlds()
	load_user_worlds()

func load_user_worlds():
	unload_user_worlds()
	
	var dir = Directory.new()

	dir.open("user://")
	if !dir.dir_exists(user_worlds_folder):
		dir.make_dir(user_worlds_folder)
		
		var copy_all_worlds = _add_base_game_worlds_to_user_worlds_folder()
		
		if copy_all_worlds != OK: return
	
	if dir.dir_exists(user_worlds_folder):
		dir.change_dir(user_worlds_folder)
		dir.list_dir_begin(true, true)
		while true:
			var current: String = dir.get_next()
			if current == "":
				break
			else:
				_get_user_world_data(current)

# Add all levels from the base game (world1, bonus1, bonus2)
# into the User Levels directory so that users can edit them!
func _add_base_game_worlds_to_user_worlds_folder() -> int:
	var dir = Directory.new()
	var file = File.new()
	
	var levels_directory = Global.globalise_path(Global.worlds_folder)
	
	if dir.dir_exists(levels_directory):
		
		var worlds = Global.list_files_in_directory(levels_directory)
		for world in worlds:
			var world_path = levels_directory + world + "/"
			var user_world_path = user_worlds_directory + world + "/"
			
			# Don't copy the world if it lacks a world.data file.
			var world_data_filepath = world_path + world_data_file
			
			if !file.file_exists(world_data_filepath):
				push_error("No world data file found for base game world: " + world + ", expected file: " + world_data_filepath)
				continue
			
			# If the world folder already exists in the user directory, don't copy it
			if dir.dir_exists(user_world_path): continue
			
			var world_copy = Global.copy_directory_recursively(world_path, user_world_path)
			
			if world_copy != OK:
				push_error("Error world from directory " + world_path + " to " + user_world_path + " Error code: " + str(world_copy))
				return world_copy
		
	else:
		push_error("Error copying base worlds levels into user worlds folder: Couldn't find levels directory at: " + levels_directory)
		return ERR_FILE_NOT_FOUND
	
	return OK

func _get_user_world_data(dir_name: String) -> bool:
	var dir = Directory.new()

	# If contrib pack data exists for the current user world:
	if dir.dir_exists(user_worlds_directory + dir_name) and dir.file_exists(user_worlds_directory + dir_name + "/" + world_data_file):
		var world_data_file_path = user_worlds_directory + dir_name + "/" + world_data_file
		
		var file = File.new()
		var world_data = file.open(world_data_file_path, File.READ)
		
		if world_data == OK:
			
			var world_variables = file.get_var()
			
			if !world_variables:
				push_error("Error getting user world data in directory: " + str(dir_name))
				return false
			
			var data : Dictionary = world_variables
			file.close()
			
			user_worlds[dir_name] = data
			return true
		else:
			push_error("Error getting user world data in directory: " + str(dir_name))
			return false
		
	
	return false

# Creates a user world.
# Returns 0 (OK) if creation is successful, else an error code (INT)
func create_user_world(world_name : String, author_name : String, create_worldmap = true) -> int:
	# Set the name of the folder the world will be stored in to
	# the world's name in snake_case.
	var world_folder_name = world_name.replace(" ", "_").to_lower()
	
	# Remove all non alphanumeric characters from the world folder name
	# to prevent errors creating the directory.
	var r = RegEx.new()
	r.compile("[^a-zA-Z0-9 -]")
	world_folder_name = r.sub(world_folder_name, "", true)
	
	var world_directory = user_worlds_directory + world_folder_name
	
	var dir = Directory.new()
	
	# If a directory for the world we want to create already exists.
	# don't proceed further so we don't overwrite anything.
	if dir.dir_exists(world_directory):
		push_error(str("Error creating user world '" + world_name + "' - World folder already exists!"))
		return ERR_ALREADY_EXISTS
	else:
		
		# Create a folder for the world to reside in.
		dir.make_dir_recursive(world_directory)
		
		var world_data_file_path = world_directory + "/" + world_data_file
		
		# Create a contrib data file for the world.
		var file = File.new()
		var world_data_file = file.open(world_data_file_path, file.WRITE)
		
		# If we can successfully open this file:
		if world_data_file == OK:
			
			# Create the world data file.
			var world_data = _create_world_data(world_name, author_name)
			
			file.store_var(world_data)
			file.close()
			
			if create_worldmap:
				var worldmap_path = world_directory + "/" + worldmap_file
				
				var worldmap_success = dir.copy(default_worldmap_level, worldmap_path)
				if worldmap_success == OK:
					return OK
					
				else:
					# If we failed creating a worldmap for the world,
					# remove the entire thing. No use leaving it half-complete.
					dir.remove(world_directory)
					
					push_error(str("Error creating Worldmap file for User World at path: " + str(worldmap_success) + ", Error code: " + str(world_data_file)))
					return worldmap_success
			
			return OK
		
		# Otherwise, return an error and exit.
		else:
			push_error(str("Error creating User World data file at path: " + str(world_data_file) + ", Error code: " + str(world_data_file)))
			return world_data_file


# Change the name / author of an existing user world
func modify_user_world(world_name : String, author_name : String, world_folder_name : String = current_world) -> int:
	var world_directory = user_worlds_directory + world_folder_name
	var dir = Directory.new()
	
	# Ensure the world exists before trying to modify it.
	if !dir.dir_exists(world_directory):
		push_error("Error modifying user world - no world exists under name: " + world_folder_name)
		return ERR_DOES_NOT_EXIST
	
	var world_data_file_path = world_directory + "/" + world_data_file
	
	# Load the contrib data file for the world.
	var file = File.new()
	var world_data_file = file.open(world_data_file_path, file.WRITE)
	
	# If we can successfully open this file:
	if world_data_file == OK:
		var world_data = _create_world_data(world_name, author_name)
		
		file.store_var(world_data)
		file.close()
		reload_user_worlds()
		
		return OK
	else:
		push_error("Error modifying world data file for user world.")
		return world_data_file

func unload_user_worlds():
	user_worlds = {}


# Creates a new level within the user world you specify.
# Names the level "levelX.tscn" where X is an automatically incrementing integer.

# Returns the file path of the created level.
func create_level_in_world(world_folder : String = current_world) -> String:
	var number_of_levels = get_levels_in_world(world_folder).size()
	var level_name = "level" + str(number_of_levels + 1) + ".tscn"
	
	var world_directory = user_worlds_directory + world_folder
	var level_filepath = world_directory + "/" + level_name
	
	var dir = Directory.new()
	if !dir.dir_exists(world_directory):
		push_error("Error creating level in world '" + world_folder + "': world folder does not exist.")
	
	if dir.file_exists(level_filepath):
		push_error("Error creating level '" + level_filepath + "': level already exists!")
	
	var level_created = dir.copy(default_level_template, level_filepath)
	if level_created == OK:
		return level_filepath
	else:
		push_error("Error creating new level at filepath: " + level_filepath)
	
	return ""

func get_world_name(world_folder : String = current_world) -> String:
	return _get_world_parameter(world_folder, "world_name")

func get_world_author(world_folder : String = current_world) -> String:
	return _get_world_parameter(world_folder, "author_name")

func get_worldmap_filename_for_world(world_folder : String = current_world) -> String:
	return _get_world_parameter(world_folder, "worldmap_scene")

func get_worldmap_filepath_for_world(world_folder : String = current_world) -> String:
	var worldmap_file = get_worldmap_filename_for_world(world_folder)
	
	var worldmap_path = user_worlds_directory + world_folder + "/" + worldmap_file
	return worldmap_path

func get_initial_scene_filepath_for_world(world_folder : String = current_world) -> String:
	var initial_scene_file = _get_world_parameter(world_folder, "initial_scene")
	
	var initial_scene_path = user_worlds_directory + world_folder + "/" + initial_scene_file
	return initial_scene_path

func _get_world_parameter(world_folder : String, parameter : String):
	if user_worlds.size() == 0:
		load_user_worlds()
	
	if user_worlds.keys().has(world_folder):
		var world_data : Dictionary = user_worlds.get(world_folder)
		
		if world_data.has(parameter):
			return world_data.get(parameter)
	
	return null

func get_world_folder_from_name(world_name : String):
	if user_worlds.size() == 0:
		load_user_worlds()
	
	var worlds_data = user_worlds.keys()
	
	for world in worlds_data:
		
		var world_data : Dictionary = user_worlds.get(world)
		
		if world_data.keys().has("world_name"):
			if world_data.get("world_name") == world_name:
				return world


# Returns the file paths for each level in a user world,
# EXCLUDING the worldmap.
func get_levels_in_world(world_folder_name : String) -> Array:
	var dir = Directory.new()
	var world_folder = user_worlds_folder + world_folder_name
	
	var worldmap_file = get_worldmap_filename_for_world(world_folder_name)
	
	var levels = []
	
	dir.open("user://")
	if !dir.dir_exists(world_folder):
		push_error("Error getting levels for world: '" + world_folder_name + "' - world folder not found!")
		return []
	
	dir.change_dir(world_folder)
	
	dir.list_dir_begin(true, true)
	while true:
		var current: String = dir.get_next()
		if current == "":
			break
		else:
			if (current.ends_with(".tscn")):
				if current != worldmap_file:
					levels.append(current)
	
	levels.sort_custom(Global, "sort_alphabetically")
	
	var level_filepaths = []
	
	for level_name in levels:
		var level_path = user_worlds_directory + world_folder_name + "/" + level_name
		level_filepaths.append(level_path)
	
	return level_filepaths

func delete_user_world(world_folder_name : String):
	var world_folder = user_worlds_folder + world_folder_name + "/"
	
	var dir = Directory.new()
	dir.open("user://")
	dir.change_dir(world_folder)
	
	# Delete all files in the world
	dir.list_dir_begin(true, true)
	while true:
		var current: String = dir.get_next()
		if current == "":
			break
		else:
			print(current)
			dir.remove(current)
	
	# Delete the world folder
	dir.remove(user_worlds_directory + world_folder_name)

func delete_user_level(level_filepath : String):
	var dir = Directory.new()
	dir.remove(level_filepath)

func _create_world_data(world_name : String, author_name : String, worldmap_scene : String = worldmap_file, initial_scene : String = worldmap_file) -> Dictionary:
	return {
		"world_name" : world_name,
		"author_name" : author_name,
		"worldmap_scene" : worldmap_scene,
		"initial_scene" : initial_scene,
	}

func open_user_worlds_folder():
	load_user_worlds()
	
	var dir = Global.globalise_path(user_worlds_directory)
	
	OS.shell_open(dir)

# Opens the folder of a specific user world
func open_user_world_folder(world_folder_name : String):
	var dir = Global.globalise_path(user_worlds_directory + world_folder_name)
	
	OS.shell_open(dir)

func get_custom_music_tracks_for_world(world : String = UserLevels.current_world):
	if !world: return
	
	var custom_music_folder = user_worlds_directory.plus_file(world).plus_file("assets/music")
	
	var dir = Directory.new()
	
	var tracks = []
	
	if dir.dir_exists(custom_music_folder):
		var files = Global.list_files_in_directory(custom_music_folder)
		for file in files:
			var file_path = custom_music_folder.plus_file(file)
			
			for music_file_type in Global.accepted_music_file_types:
				if file.ends_with(music_file_type):
					tracks.append(file_path)
					continue
	
	if tracks == []: return null
	
	else: return tracks

# Opens the folder for custom assets in a user world.
# Also creates said folder if it does not yet exist.
# If subfolder is specified, creates a folder within the custom assets folder for the subfolder.

func open_user_world_custom_assets_folder(subfolder : String = "", world_folder : String = current_world):
	print("Open user assets folder: " + subfolder)
	
	var folder_to_open = user_worlds_directory.plus_file(world_folder).plus_file("assets")
	if subfolder != "":
		folder_to_open = folder_to_open.plus_file(subfolder)
	
	var dir = Directory.new()
	if !dir.dir_exists(folder_to_open):
		dir.make_dir_recursive(folder_to_open)
	
	yield(get_tree(), "idle_frame")
	
	folder_to_open = Global.globalise_path(folder_to_open)
	
	OS.shell_open(folder_to_open)

func _is_custom_content_supported():
	return !OS.has_feature("mobile") and !OS.has_feature("HTML5")
