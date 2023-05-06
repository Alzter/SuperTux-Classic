extends PopupDialog

onready var open_world_button = $VBoxContainer/OpenWorldButton
onready var back_button = $VBoxContainer/Back

onready var world_list = $VBoxContainer/ScrollContainer/WorldList

export var world_button_scene : PackedScene

func _on_OpenWorldMenu_about_to_show():
	UserLevels.load_user_worlds()
	_clear_world_list()
	
	for world in UserLevels.user_worlds:
		var button = world_button_scene.instance()
		world_list.add_child(button)
		button.init(world)
		button.owner = world_list
	
	world_list.show()

func _on_Back_pressed():
	hide()

func _clear_world_list():
	for child in world_list.get_children():
		child.queue_free()
	
func _on_OpenWorldMenu_popup_hide():
	_clear_world_list()
