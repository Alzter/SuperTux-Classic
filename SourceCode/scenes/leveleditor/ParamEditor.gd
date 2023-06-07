extends Control

var parameter_owner_object : Node = null # Base object which CONTAINS the desired parameter
var parameter_name = null
var parameter_type = null

onready var label = $Label
onready var number_edit = $SpinBox
onready var string_edit = $LineEdit
onready var color_edit = $ColorPickerButton
onready var bool_edit = $CheckBox
onready var dropdown_edit = $OptionButton
onready var level_path_edit = $SelectLevel
onready var dialog_select_level = $SelectLevelDialog

var dropdown_values : Dictionary = {}

onready var editor_nodes = [
	number_edit,
	string_edit,
	color_edit,
	bool_edit,
	string_edit,
	level_path_edit
]

var param_editor_ui_node = null

signal parameter_changed

func init(owner_object : Node, param_name : String, param_type : int):
	parameter_owner_object = owner_object
	parameter_name = param_name
	parameter_type = param_type

func _ready():
	dialog_select_level.connect("level_opened", self, "level_selected")
	
	if !parameter_name or !parameter_type or !parameter_owner_object:
		push_error("Error creating Parameter Editor. Missing parameter name, type, or owner object.")
		queue_free()
		return
	
	label.text = parameter_name.capitalize()
	label.show()
	
	for ui_node in editor_nodes:
		ui_node.hide()
	
	_update_parameter_value()
	
	param_editor_ui_node.show()

func _update_parameter_value():
	# Store the CURRENT VALUE of the parameter in p_value
	var p_value = _get_parameter_value()
	
	match parameter_type:
		TYPE_INT:
			number_edit.rounded = true
			number_edit.value = p_value
			number_edit.step = 1
			param_editor_ui_node = number_edit
			
		TYPE_REAL: # Float data type
			number_edit.rounded = false
			number_edit.value = p_value
			param_editor_ui_node = number_edit
			
		TYPE_STRING:
			# IF THE STRING IS A PATH TO A LEVEL (e.g. "res://scenes/levels/world1/level1.tscn")
			# We treat it differently to a regular string and allow the user to choose a level
			# from a dropdown.
			
			if Global.string_is_scene_path(p_value):
				_update_level_selector_text()
				param_editor_ui_node = level_path_edit
			else:
				string_edit.text = p_value
				param_editor_ui_node = string_edit
			
		TYPE_BOOL:
			bool_edit.pressed = p_value
			param_editor_ui_node = bool_edit
			
		TYPE_COLOR:
			color_edit.color = p_value
			param_editor_ui_node = color_edit
		
		TYPE_ARRAY:
			if p_value.size() == 2:
				param_editor_ui_node = dropdown_edit
				_populate_dropdown_menu(p_value)
			else:
				push_error("ERROR creating layer parameter editor. Arrays must follow format: [String, Array<String>], where String contains a current value and Array contains a list of all possible values")
				queue_free()
				return
		
		_: # If the data type is not matched, do not create a parameter editor.
			push_error(str("ERROR creating layer parameter editor. Unrecognised parameter type: " + str(parameter_type)))
			queue_free()
			return

# Normally, spinboxes only register that their value is changed when ENTER is pressed.
# We try to circumvent this by constantly feeding the spinbox value to the object editor.
func _process(delta):
	if param_editor_ui_node == number_edit:
		if number_edit.value:
			_on_SpinBox_value_changed(number_edit.value)

func _populate_dropdown_menu(dropdown_array):
	var selected_item = dropdown_array[0]
	var items = dropdown_array[1]
	
	var id = 0
	for item in items:
		dropdown_edit.add_item(item, id)
		dropdown_values[item] = id
		if selected_item == item: dropdown_edit.select(id)
		id += 1

func _get_parameter_value():
	return parameter_owner_object.get(parameter_name)

func _set_parameter_value(new_value):
	parameter_owner_object.set(parameter_name, new_value)
	
	if [TYPE_INT, TYPE_REAL].has(parameter_type):
		_update_parameter_value()

# ==================================================
# UPDATING THE PARAMETER WHEN THE UI NODE IS ADJUSTED BY THE USER

func _on_LineEdit_text_changed(new_text):
	_set_parameter_value(new_text)
	emit_signal("parameter_changed")

func _on_SpinBox_value_changed(value):
	_set_parameter_value(value)
	emit_signal("parameter_changed")

func _on_ColorPickerButton_color_changed(color):
	_set_parameter_value(color)

func _on_CheckBox_toggled(button_pressed):
	_set_parameter_value(button_pressed)

# If we change the current selected option for the dropdown
func _on_OptionButton_item_selected(index):
	
	# Get the Value of the ID of the new selected option.
	var dropdown_value = null
	for id in dropdown_values.values():
		if id == index:
			dropdown_value = dropdown_values.keys()[id]
	
	if dropdown_value:
		
		# Dropdowns are stored in an array data structure
		# where the first item is the currently selected item,
		# and the second is an array of all items.
		
		# We update the dropdown array to reflect the new selected item.
		var dropdown_array = _get_parameter_value()
		dropdown_array[0] = dropdown_value
		_set_parameter_value(dropdown_array)
	else:
		push_error("Error getting value for dropdown item with index " + str(index))

func _on_SelectLevel_pressed():
	dialog_select_level.popup_centered_ratio()

func level_selected(level_filepath : String):
	_set_parameter_value(level_filepath)
	_update_level_selector_text()

func _update_level_selector_text():
	var level_path = _get_parameter_value()
	var level_name = Global.get_level_attribute(level_path, "level_title")
	
	if level_name:
		level_path_edit.text = level_name
