extends PopupDialog

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
	UserLevels.create_user_world(world_name.text, author_name.text)
