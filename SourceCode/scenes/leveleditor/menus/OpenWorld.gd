extends PopupDialog

onready var open_world_button = $VBoxContainer/OpenWorldButton
onready var back_button = $VBoxContainer/Back

onready var world_list = $VBoxContainer/ScrollContainer/WorldList

export var world_button_scene : PackedScene

func _on_OpenWorldMenu_about_to_show():
	UserLevels.load_user_worlds()
	world_list.show()
	
	for world in UserLevels.user_worlds:
		var button = world_button_scene.instance()
		world_list.add_child(button)
		button.init(world)
		button.owner = world_list
#		var name = UserLevels.get_world_name(world)
#		var author = UserLevels.get_world_author(world)
#
#		var levels = UserLevels.get_levels_in_world(world)
#		var number_of_levels = levels.size()
#
#		print(name)
#		print(author)
#		print(number_of_levels)

func _on_Back_pressed():
	hide()

func _on_OpenWorldMenu_popup_hide():
	for child in world_list.get_children():
		child.queue_free()
