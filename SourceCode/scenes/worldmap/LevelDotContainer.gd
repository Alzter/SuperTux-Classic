extends Node2D
export var debug = false

func _ready():
	if debug:
		for leveldot in get_children():
			if !leveldot.is_teleporter:
				if Global.in_contrib:
					var new_path: String = leveldot.level_file_path
					if not new_path.begins_with("user://"):
						new_path = "user://contrib/" + Global.current_contrib + "/" + new_path
					leveldot.level_file_path = new_path
				leveldot.level_cleared = true
		return
	
	for leveldot in get_children():
		if !leveldot.is_teleporter:
			if Global.in_contrib:
				var new_path: String = leveldot.level_file_path
				if not new_path.begins_with("user://"):
					new_path = "user://contrib/" + Global.current_contrib + "/" + new_path
				leveldot.level_file_path = new_path
			if WorldmapManager.cleared_levels.has(leveldot.level_file_path):
				leveldot.level_cleared = true
