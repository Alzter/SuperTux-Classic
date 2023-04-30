extends Popup

# TODO

func _ready():
	for i in Global.contrib_data.keys():
		var content: ConfigFile = Global.contrib_data[i]
		
		var button = Button.new()
		button.text = content.get_value("contrib", "name")
		button.connect("pressed", self, "set_contrib_pack", [i])
		button.connect("pressed", self, "contrib_goto_scene", [i, "user://contrib/" + i + "/" + content.get_value("contrib", "worldmap")])
		$Panel/ScrollContainer/VBoxContainer.add_child(button)

func set_contrib_pack(pack: String):
	Global.current_contrib = pack

func _on_Done_pressed():
	hide()
	get_parent().bonus_levels_menu.popup()

func _on_Done_mouse_entered():
	if visible: $Panel/Done.grab_focus()

func _on_Done_mouse_exited():
	$Panel/Done.focus_mode = Control.FOCUS_NONE

func _on_Custom_pressed():
	get_parent()._on_LevelSelectDebug_pressed()

func contrib_goto_scene(contrib: String, val: String):
	Global.in_contrib = true
	Global.current_contrib = contrib
	var save_path = SaveManager.contrib_save.format({"ct": Global.current_contrib})
	
	if SaveManager.has_savefile(save_path):
		SaveManager.load_game(save_path)
	else:
		var worldmap = "user://contrib/" + contrib + "/" + Global.contrib_data[contrib].get_value("contrib", "worldmap")
		var initial = Global.contrib_data[contrib].get_value("contrib", "initial")
		if initial == null:
			initial = worldmap
		SaveManager.new_game(initial, worldmap)
