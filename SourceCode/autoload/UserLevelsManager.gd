extends Node

const user_worlds_directory = "user://contrib/"
const world_data_file = "contrib.data"

var user_contrib_data: Dictionary = {}

func load_user_contrib():
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
				load_user_world_data(current)

func load_user_world_data(dir_name: String) -> bool:
	var dir = Directory.new()

	# If contrib pack data exists for the current user world:
	if dir.dir_exists("user://contrib/" + dir_name) and dir.file_exists("user://contrib/" + dir_name + "/contrib.data"):
		var file = ConfigFile.new()
		file.load("user://contrib/" + dir_name + "/world.data")
		user_contrib_data[dir_name] = file
		return true
	
	return false

# Creates a user world.
# Returns 0 (OK) if creation is successful, else an error code (INT)
func create_user_world(world_name : String, author_name : String) -> int:
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
			return OK
		
		# Otherwise, return an error and exit.
		else:
			push_error(str("Error creating User World data file at path: " + str(world_data_file) + ", Error code: " + str(world_data_file)))
			return world_data_file

func _create_world_data(world_name : String, author_name : String, worldmap_scene : String = "worldmap.tscn", initial_scene : String = "worldmap.tscn") -> Dictionary:
	return {
		"world_name" : world_name,
		"author_name" : author_name,
		"worldmap_scene" : worldmap_scene,
		"initial_scene" : initial_scene,
	}
