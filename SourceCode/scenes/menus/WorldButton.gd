extends Button

export var world_to_load = "world1"
export var initial_scene_for_world = "res://scenes/levels/world1/intro.tscn"

func _on_WorldButton_mouse_entered():
	if !disabled:
		grab_focus()

func _on_WorldButton_pressed():
	if !disabled:
		if world_to_load != "" and initial_scene_for_world != "":
			SaveManager.load_world(world_to_load, initial_scene_for_world)
