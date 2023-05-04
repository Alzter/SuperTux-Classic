extends Node

const user_worlds_directory = "user://contrib/"
const world_data_file = "contrib.data"
const worldmap_file = "worldmap.tscn"

var default_worldmap_level = "res://scenes/leveleditor/level_templates/worldmap.tscn"

var user_worlds: Dictionary = {}

func load_user_worlds():
	var dir = Directory.new()

	dir.open("user://")
	if !dir.dir_exists("contrib"):
		dir.make_dir("contrib")
	else:
		dir.change_dir("contrib")
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
	if dir.dir_exists("user://contrib/" + dir_name) and dir.file_exists("user://contrib/" + dir_name + "/contrib.data"):
		var world_data_file_path = "user://contrib/" + dir_name + "/contrib.data"
		
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
				if worldmap_success:
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

func get_worldmap_scene_for_world(world_name : String):
	return _get_world_parameter(world_name, "worldmap_scene")

func get_initial_scene_for_world(world_name : String):
	return _get_world_parameter(world_name, "initial_scene")

func _get_world_parameter(world_name : String, parameter : String):
	if user_worlds == {}: load_user_worlds()
	
	if user_worlds.keys().has(world_name):
		var world_data = user_worlds.get(world_name)
		
		if world_data.has(parameter):
			return world_data.get(parameter)
	
	return null

func _create_world_data(world_name : String, author_name : String, worldmap_scene : String = worldmap_file, initial_scene : String = worldmap_file) -> Dictionary:
	return {
		"world_name" : world_name,
		"author_name" : author_name,
		"worldmap_scene" : worldmap_scene,
		"initial_scene" : initial_scene,
	}
