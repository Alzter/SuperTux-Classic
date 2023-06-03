extends Popup

export var world_button_scene : PackedScene
onready var world_container = $Panel/VBoxContainer/PanelContainer/ScrollContainer/WorldContainer
onready var back_button = $Panel/VBoxContainer/Back

func _on_CustomLevelsMenu_about_to_show():
	if world_container.get_child_count() != 0:
		return
	
	UserLevels.load_user_worlds()
	
	for world in UserLevels.user_worlds:
		
		var button = world_button_scene.instance()
		world_container.add_child(button)
		button.set_owner(world_container)
		
		button.world_to_load = world
		button.initial_scene_for_world = UserLevels.get_initial_scene_filepath_for_world(world)
		button.text = UserLevels.get_world_name(world)
		button.rect_min_size.y = 42

func _on_Back_mouse_entered():
	back_button.grab_focus()
	
func _on_Back_pressed():
	hide()

