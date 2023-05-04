extends PopupDialog

onready var error_dialog = $ErrorDialog
onready var error_ok_button = $ErrorDialog/VBoxContainer/ErrorEscape

onready var world_name = $VBoxContainer/WorldProperties/WorldName/WorldNameEdit
onready var author_name = $VBoxContainer/WorldProperties/AuthorName/AuthorNameEdit

onready var world_name_container = $VBoxContainer/WorldProperties/WorldName

onready var create_world_button = $VBoxContainer/CreateWorldButton

func _on_CreateWorldMenu_about_to_show():
	world_name.text = ""
	author_name.text = ""
	world_name_container.grab_focus()
	create_world_button.disabled = true

func _on_Back_pressed():
	hide()

func _on_CreateWorldButton_pressed():
	var created_world = UserLevels.create_user_world(world_name.text, author_name.text)
	
	if created_world == OK:
		var world_folder = UserLevels.get_world_folder_from_name(world_name.text)
		
		var worldmap_scene_path = UserLevels.get_worldmap_filepath_for_world(world_folder)
		Global.load_level_editor(worldmap_scene_path)
	else:
		error_dialog.popup()

func _on_ErrorEscape_pressed():
	error_dialog.hide()
	world_name_container.grab_focus()

func _on_ErrorDialog_about_to_show():
	error_ok_button.grab_focus()


func _on_AuthorNameEdit_text_changed(new_text):
	_enable_create_world_button_if_world_fields_are_full()

func _on_WorldNameEdit_text_changed(new_text):
	_enable_create_world_button_if_world_fields_are_full()

func _enable_create_world_button_if_world_fields_are_full():
	create_world_button.disabled = author_name.text.replace(" ", "") == "" or world_name.text.replace(" ", "") == ""
