extends Node

const user_worlds_directory = "user://contrib/"
const user_worlds_folder = "contrib/"
const world_data_file = "contrib.data"
const worldmap_file = "worldmap.tscn"

var default_worldmap_level = "res://scenes/leveleditor/level_templates/worldmap.tscn"

var user_worlds: Dictionary = {}

var current_world = null

func load_user_worlds():
	unload_user_worlds()
	
	var dir = Directory.new()

	dir.open("user://")
	if !dir.dir_exists(user_worlds_folder):
		dir.make_dir(user_worlds_folder)
	else:
		dir.change_dir(user_worlds_folder)
		dir.list_dir_begin(true, true)
		while true:
			var current: String = dir.get_next()
			if current == "":
				break
			else:
				_get_user_world_data(current)

func _get_user_world_data(dir_name: String) -> bool:
	var dir = Directory.new()

	# If contrib pack data exists for the current user world:
	if dir.dir_exists(user_worlds_directory + dir_name) and dir.file_exists(user_worlds_directory + dir_name + "/" + world_data_file):
		var world_data_file_path = user_worlds_directory + dir_name + "/" + world_data_file
		
		var file = File.new()
		var world_data = file.open(world_data_file_path, File.READ)
		
		if world_data == OK:
			var data : Dictionary = file.get_var()
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

func unload_user_worlds():
	user_worlds = {}

func get_world_name(world_folder : String) -> String:
	return _get_world_parameter(world_folder, "world_name")

func get_world_author(world_folder : String) -> String:
	return _get_world_parameter(world_folder, "author_name")

func get_worldmap_filename_for_world(world_folder : String) -> String:
	return _get_world_parameter(world_folder, "worldmap_scene")

func get_worldmap_filepath_for_world(world_folder : String) -> String:
	var worldmap_file = get_worldmap_filename_for_world(world_folder)
	
	var worldmap_path = user_worlds_directory + world_folder + "/" + worldmap_file
	return worldmap_path

func get_initial_scene_filepath_for_world(world_folder : String) -> String:
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
