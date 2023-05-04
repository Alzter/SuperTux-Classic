extends PopupDialog

onready var error_dialog = $ErrorDialog
onready var error_ok_button = $ErrorDialog/VBoxContainer/ErrorEscape

onready var world_name = $VBoxContainer/WorldProperties/WorldName/WorldNameEdit
onready var author_name = $VBoxContainer/WorldProperties/AuthorName/AuthorNameEdit

onready var world_name_container = $VBoxContainer/WorldProperties/WorldName

func _on_CreateWorldMenu_about_to_show():
	world_name.text = ""
	author_name.text = ""
	world_name_container.grab_focus()

func _on_Back_pressed():
	hide()

func _on_CreateWorldButton_pressed():
	var created_world = UserLevels.create_user_world(world_name.text, author_name.text)
	
	if created_world == OK:
		pass
	else:
		error_dialog.popup()

func _on_ErrorEscape_pressed():
	error_dialog.hide()
	world_name_container.grab_focus()

func _on_ErrorDialog_about_to_show():
	error_ok_button.grab_focus()
