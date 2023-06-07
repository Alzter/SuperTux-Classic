extends PopupDialog

var is_editing_object = false

var node_to_edit : Node = null

export var parameter_editor_scene : PackedScene

onready var title = $VBoxContainer/Title
onready var layer_parameters = $VBoxContainer/PanelContainer/ScrollContainer/LayerParameters

signal layer_parameter_changed

func appear(node_being_edited : Node, node_is_object : bool):
	node_to_edit = node_being_edited
	is_editing_object = node_is_object
	popup_centered_ratio()

func _on_EditLayerDialog_about_to_show():
	if !node_to_edit:
		hide()
		return
	
	if is_editing_object: title.text = "Edit Object..."
	else: title.text = "Edit Layer..."
	
	# Create a "Name" editor for the layer being edited
	if !is_editing_object:
		_create_parameter_editor(node_to_edit, "name", TYPE_STRING)
	
	# Get the layer parameters of the desired layer, if any exist
	var parameters = node_to_edit.get("editor_params")
	if parameters:
		
		# FOR EVERY LAYER PARAMETER:
		for param_string in parameters:
			var p = node_to_edit.get(param_string)
			var param_name = param_string
			var param_type = typeof(p)
			
			_create_parameter_editor(node_to_edit, param_name, param_type)

# Creates a parameter editor object for a parameter.
func _create_parameter_editor(parameter_owner_object : Node, param_name : String, param_type : int):
	var param_editor_node = parameter_editor_scene.instance()
	
	param_editor_node.init(parameter_owner_object, param_name, param_type)
	
	layer_parameters.add_child(param_editor_node)
	param_editor_node.set_owner(layer_parameters)
	param_editor_node.connect("parameter_changed", self, "_layer_parameter_changed")
	#print(layer_parameters.get_children())

func _on_ConfirmEditLayer_pressed():
	hide()

func _on_EditLayerDialog_popup_hide():
	for param_editor in layer_parameters.get_children():
		param_editor.release_focus()
	yield(get_tree(), "idle_frame")
	
	owner.play_sound("EditLayerComplete")
	
	call_deferred("_deferred_hide_layer_editor")

# It is now safe to hide the layer editor and delete all parameter editors
func _deferred_hide_layer_editor():
	node_to_edit = null
	
	for child in layer_parameters.get_children():
		child.free()

func _layer_parameter_changed():
	emit_signal("layer_parameter_changed")

func _input(event):
	if Input.is_action_pressed("ui_accept"):
		yield(get_tree(), "idle_frame") # This has to be here or else the play level input registers too
		hide()
