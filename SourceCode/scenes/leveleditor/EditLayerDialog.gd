extends PopupDialog

var layer_being_edited : Node = null

export var parameter_editor_scene : PackedScene

onready var layer_parameters = $VBoxContainer/PanelContainer/LayerParameters

func appear(layer_to_edit : Node):
	layer_being_edited = layer_to_edit
	popup()

func _on_EditLayerDialog_about_to_show():
	if !layer_being_edited: return
	
	# Get the layer parameters of the desired layer, if any exist
	var parameters = layer_being_edited.get("editor_params")
	if parameters:
		
		# FOR EVERY LAYER PARAMETER:
		for param_string in parameters:
			var p = layer_being_edited.get(param_string)
			var param_name = param_string
			var param_type = typeof(p)
			
			_create_parameter_editor(layer_being_edited, param_name, param_type)

# Creates a parameter editor object for a parameter.
func _create_parameter_editor(parameter_owner_object : Node, param_name : String, param_type : int):
	var param_editor_node = parameter_editor_scene.instance()
	
	param_editor_node.init(parameter_owner_object, param_name, param_type)
	
	layer_parameters.add_child(param_editor_node)
	param_editor_node.set_owner(layer_parameters)
	print(layer_parameters.get_children())

func _on_ConfirmEditLayer_pressed():
	hide()

func _on_EditLayerDialog_popup_hide():
	call_deferred("_deferred_hide_layer_editor")

# It is now safe to hide the layer editor and delete all parameter editors
func _deferred_hide_layer_editor():
	layer_being_edited = null
	
	for child in layer_parameters.get_children():
		child.free()
