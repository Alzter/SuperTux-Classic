extends Node

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

