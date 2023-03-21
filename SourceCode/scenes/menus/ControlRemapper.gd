extends Control

export var action_to_remap = "move_left"
var is_being_changed = false setget _update_button_state

onready var button = $RemapButton
onready var label = $Label

func _ready():
	label.text = action_to_remap.capitalize()
	self.is_being_changed = false

func _set_button_text_to_control_action():
	button.text = InputMap.get_action_list(action_to_remap)[0].as_text().capitalize()

func _on_RemapButton_pressed():
	self.is_being_changed = true

func _input(event):
	if !is_being_changed: return
	
	if (event is InputEventKey):
		
		InputMap.action_erase_events(action_to_remap)
		InputMap.action_add_event(action_to_remap, event)
		
		print("Remapped key " + str(action_to_remap) + " to input " + event.as_text())
		self.is_being_changed = false


# Makes the button say "Press a key..." when the button is being remapped
func _update_button_state(new_value):
	is_being_changed = new_value
	
	if is_being_changed:
		button.flat = true
		button.disabled = true
		button.text = "Press a Key..."
	else:
		button.flat = false
		button.disabled = false
		_set_button_text_to_control_action()

func _on_RemapButton_mouse_entered():
	if !is_being_changed: button.text = "Change"

func _on_RemapButton_mouse_exited():
	if !is_being_changed: _set_button_text_to_control_action()
