extends PopupDialog

onready var open_world_button = $VBoxContainer/OpenWorldButton
onready var back_button = $VBoxContainer/Back

onready var world_list = $VBoxContainer/ScrollContainer/WorldList

func _on_OpenWorldMenu_about_to_show():
	world_list.show()

func _on_Back_pressed():
	hide()

func _on_OpenWorldMenu_popup_hide():
	for child in world_list.get_children():
		child.queue_free()
