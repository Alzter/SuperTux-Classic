extends Popup

var key_to_remap = null
var remap_button = null

onready var left_button = $Panel/Controls/Left/LeftRemapButton

func _on_ControlsMenu_about_to_show():
	grab_focus()

func _on_Done_pressed():
	hide()

func _on_LeftRemapButton_pressed():
	key_to_remap = "move_left"
	remap_button = left_button
	remap_button()

func remap_button(button : Button = remap_button):
	button.grab_focus()
	button.flat = true
	button.disabled = true
	button.text = "Press a Key..."

func finish_remapping_button(button : Button = remap_button):
	button.flat = false
	button.disabled = false
	button.text = "Change"
	remap_button = null

func _input(event):
	if key_to_remap == null: return
	
	if !(event is InputEventKey or event is InputEventJoypadButton): return
	
	InputMap.action_erase_events(key_to_remap)
	InputMap.action_add_event(key_to_remap, event)
	
	print("Remapped key " + str(key_to_remap) + " to input " + event.as_text())
	finish_remapping_button()
	key_to_remap = null

