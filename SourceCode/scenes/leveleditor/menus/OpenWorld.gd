extends PopupDialog

onready var open_world_button = get_node_or_null("VBoxContainer/OpenWorldButton")
onready var open_level_button = get_node_or_null("VBoxContainer/OpenLevelButton")
onready var back_button = $VBoxContainer/Back

export var is_level_select = false

onready var button_list = get_node_or_null("VBoxContainer/ScrollContainer/ButtonList")

onready var select_level_dialog = get_node_or_null("SelectLevelDialog")

export var button_scene : PackedScene

var selected_world = ""
var selected_level = ""

func _on_Menu_about_to_show():
	selected_world = ""
	selected_level = ""
	_clear_button_list()
	
	if is_level_select: _populate_level_list()
	else:
		UserLevels.load_user_worlds()
		_populate_world_list()
	
	button_list.show()

func _populate_world_list():
	if UserLevels.user_worlds.size() == 0: return
	
	for world in UserLevels.user_worlds:
		var button = button_scene.instance()
		button_list.add_child(button)
		button.owner = button_list
		button.connect("world_selected", self, "world_selected")
		button.connect("world_opened", self, "world_opened")
		button.connect("world_delete_prompt", self, "world_delete_prompt")
		button.init_world(world)
	
	var first_world = UserLevels.user_worlds.keys().front()
	world_selected(first_world)

func _populate_level_list():
	
	var levels = UserLevels.get_levels_in_world(UserLevels.current_world)
	
	if levels.size() == 0: return
	
	var worldmap_level = UserLevels.get_worldmap_filepath_for_world(UserLevels.current_world)
	
	_add_level_button(worldmap_level, true)
	
	for level in levels:
		_add_level_button(level)
	
	level_selected(worldmap_level)
	
	return

func _add_level_button(level_filepath, is_worldmap = false):
		var button = button_scene.instance()
		button_list.add_child(button)
		button.owner = button_list
		button.connect("level_selected", self, "level_selected")
		button.connect("level_opened", self, "level_opened")
		button.connect("level_delete_prompt", self, "level_delete_prompt")
		button.init_level(level_filepath, is_worldmap)

func _on_Back_pressed():
	hide()

func _clear_button_list():
	for child in button_list.get_children():
		child.queue_free()
	
func _on_OpenWorldMenu_popup_hide():
	_clear_button_list()


func _on_OpenWorldButton_pressed():
	world_opened(selected_world)

func _on_OpenLevelButton_pressed():
	level_opened(selected_level)

func level_selected(level_filepath):
	selected_level = level_filepath
	
	for button in button_list.get_children():
		button.pressed = button.level_filepath == selected_level
		if button.pressed: button.grab_focus()

func world_selected(selected_world_folder_name):
	selected_world = selected_world_folder_name
	
	for button in button_list.get_children():
		button.pressed = button.world_folder_name == selected_world
		if button.pressed: button.grab_focus()

func world_opened(selected_world_folder_name):
	hide()
	UserLevels.current_world = selected_world_folder_name
	select_level_dialog.popup()

func level_opened(level_filepath):
	Global.load_level_editor_with_level(level_filepath)

func world_delete_prompt(selected_world_folder_name):
	pass

func _on_SelectLevelDialog_popup_hide():
	var old_selected_world = selected_world
	popup()
	world_selected(old_selected_world)

