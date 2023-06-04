extends Node2D
export var debug = false

func _ready():
	#print(Global.is_in_editor)
	#print(debug)
	
	if !is_in_group("object_container"):
		add_to_group("object_container")
	
	yield(get_tree(), "idle_frame") # Force godot to process parent before child
	
	if debug or Global.is_in_editor:
		for leveldot in get_children():
			if !leveldot.is_teleporter:
				leveldot.level_cleared = true
		return
	
	if WorldmapManager.cleared_levels != []:
		
		for leveldot in get_children():
			if !leveldot.is_teleporter:
				if WorldmapManager.cleared_levels.has(leveldot.level_file_path):
					leveldot.level_cleared = true
