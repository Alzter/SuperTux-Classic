extends Node2D
export var debug = false

func _ready():
	#print(Global.is_in_editor)
	#print(debug)
	
	if !is_in_group("object_container"):
		add_to_group("object_container")
	
	yield(get_tree(), "idle_frame") # Force godot to process parent before child
	
	var clear = debug or Global.is_in_editor
	for child in get_children():
		if !child.is_in_group("leveldots"): continue
		
		if !child.is_teleporter:
			child.level_cleared = clear
	
	if WorldmapManager.cleared_levels != []:
		
		for child in get_children():
			if !child.is_in_group("leveldots"): continue
			
			if !child.is_teleporter:
				if WorldmapManager.cleared_levels.has(child.level_file_path):
					child.level_cleared = true
