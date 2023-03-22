extends Node2D

func _ready():
	if WorldmapManager.cleared_levels != []:
		
		for leveldot in get_children():
			if !leveldot.is_teleporter:
				if WorldmapManager.cleared_levels.has(leveldot.level_file_path):
					leveldot.level_cleared = true
