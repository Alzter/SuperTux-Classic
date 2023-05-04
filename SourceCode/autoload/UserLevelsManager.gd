extends Node

var user_worlds_data: Dictionary = {}

func load_user_worlds():
	var dir = Directory.new()

	dir.open("user://")
	if !dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	else:
		dir.change_dir("worlds")
		dir.list_dir_begin(true, true)
		while true:
			var current: String = dir.get_next()
			if current == "":
				break
			else:
				register_user_world(current)


func register_user_world(dir_name: String) -> bool:
	var dir = Directory.new()

	# If worlds pack data exists for the current user world:
	if dir.dir_exists("user://worlds/" + dir_name) and dir.file_exists("user://worlds/" + dir_name + "/world.data"):
		var file = ConfigFile.new()
		file.load("user://worlds/" + dir_name + "/world.data")
		user_worlds_data[dir_name] = file
		return true
	
	return false
