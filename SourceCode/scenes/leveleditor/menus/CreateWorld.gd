extends PopupDialog

export var is_edit_world_menu = false

onready var error_dialog = $ErrorDialog
onready var error_ok_button = $ErrorDialog/VBoxContainer/ErrorEscape

onready var world_name = $VBoxContainer/WorldProperties/WorldName/WorldNameEdit
onready var author_name = $VBoxContainer/WorldProperties/AuthorName/AuthorNameEdit

onready var world_name_container = $VBoxContainer/WorldProperties/WorldName

onready var create_world_button = $VBoxContainer/CreateWorldButton
onready var edit_world_button = $VBoxContainer/ConfirmEditProperties

signal show_world_menu

func _on_CreateWorldMenu_about_to_show():
	if is_edit_world_menu:
		world_name.text = UserLevels.get_world_name()
		author_name.text = UserLevels.get_world_author()
	else:
		world_name.text = ""
		author_name.text = ""
	world_name_container.grab_focus()
	_enable_create_world_button_if_world_fields_are_full()

func _on_Back_pressed():
	hide()

func _on_CreateWorldButton_pressed():
	var created_world = UserLevels.create_user_world(world_name.text, author_name.text)
	
	if created_world == OK:
		UserLevels.reload_user_worlds()
		var world_folder = UserLevels.get_world_folder_from_name(world_name.text)
		hide()
		
		emit_signal("show_world_menu", world_folder)
		#var worldmap_scene_path = UserLevels.get_worldmap_filepath_for_world(world_folder)
		#Global.load_level_editor_with_level(worldmap_scene_path)
	else:
		error_dialog.popup()


func _on_ConfirmEditProperties_pressed():
	var edited_world = UserLevels.modify_user_world(world_name.text, author_name.text)
	
	if edited_world == OK:
		emit_signal("show_world_menu", UserLevels.current_world)
		hide()
	else: error_dialog.popup()

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
	var disabled = author_name.text.replace(" ", "") == "" or world_name.text.replace(" ", "") == ""
	if create_world_button: create_world_button.disabled = disabled
	if edit_world_button: edit_world_button.disabled = disabled
