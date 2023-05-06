extends PopupDialog

onready var open_world_button = $VBoxContainer/OpenWorldButton
onready var back_button = $VBoxContainer/Back

onready var world_list = $VBoxContainer/ScrollContainer/WorldList

onready var select_level_dialog = $SelectLevelDialog

export var world_button_scene : PackedScene

var selected_world = ""

func _on_OpenWorldMenu_about_to_show():
	selected_world = ""
	UserLevels.load_user_worlds()
	_clear_world_list()
	
	if UserLevels.user_worlds.size() == 0: return
	
	for world in UserLevels.user_worlds:
		var button = world_button_scene.instance()
		world_list.add_child(button)
		button.connect("world_selected", self, "world_selected")
		button.connect("world_opened", self, "world_opened")
		button.connect("world_delete_prompt", self, "world_delete_prompt")
		button.init(world)
		button.owner = world_list
	
	var first_world = UserLevels.user_worlds.keys().front()
	world_selected(first_world)
	
	world_list.show()

func _on_Back_pressed():
	hide()

func _clear_world_list():
	for child in world_list.get_children():
		child.queue_free()
	
func _on_OpenWorldMenu_popup_hide():
	_clear_world_list()

func world_selected(selected_world_folder_name):
	selected_world = selected_world_folder_name
	
	for button in world_list.get_children():
		button.pressed = button.world_folder_name == selected_world
		if button.pressed: button.grab_focus()

func _on_OpenWorldButton_pressed():
	world_opened(selected_world)

func world_opened(selected_world_folder_name):
	hide()
	select_level_dialog.popup()

func world_delete_prompt(selected_world_folder_name):
	pass

func _on_SelectLevelDialog_popup_hide():
	var old_selected_world = selected_world
	popup()
	world_selected(old_selected_world)
