extends Popup

var key_to_remap = null
var remap_button = null

onready var control_button_container = $Panel/PanelContainer/ScrollContainer/Controls
onready var done_button = $Panel/Done

export var control_remapper : PackedScene

func _on_ControlsMenu_about_to_show():
	grab_focus()
	
	if control_button_container.get_child_count() == 0:
		_populate_controls_menu()

func _populate_controls_menu():
	var show_text = true
	
	for control in Global.controls:
		var remapper = control_remapper.instance()
		remapper.action_to_remap = control
		remapper.show_button_type_names = show_text
		control_button_container.add_child(remapper)
		show_text = false
	
	control_button_container.get_children().front().grab_focus()

func _on_Done_pressed():
	hide()

func _on_ControlsMenu_popup_hide():
	yield(get_tree(), "idle_frame")
	SaveManager.save_current_controls()
	yield(get_tree(), "idle_frame")
	SaveManager.load_current_controls()
