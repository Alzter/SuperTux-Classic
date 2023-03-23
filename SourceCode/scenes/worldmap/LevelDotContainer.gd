extends Node2D
export var debug = false

func _ready():
	if debug:
		for leveldot in get_children():
			if !leveldot.is_teleporter:
				leveldot.level_cleared = true
		return
	
	if WorldmapManager.cleared_levels != []:
		
		for leveldot in get_children():
			if !leveldot.is_teleporter:
				if WorldmapManager.cleared_levels.has(leveldot.level_file_path):
					leveldot.level_cleared = true
