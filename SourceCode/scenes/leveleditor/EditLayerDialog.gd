extends PopupDialog

var layer_being_edited : Node = null

func appear(layer_to_edit : Node):
	layer_being_edited = layer_to_edit
	popup()

func _on_EditLayerDialog_about_to_show():
	if !layer_being_edited: return
	
	# Get the layer parameters of the desired layer, if any exist
	var parameters = layer_being_edited.get("editor_params")
	if parameters:
		
		# FOR EVERY LAYER PARAMETER:
		for p in parameters:
			var param_name = var2str(p).replace('"', '').capitalize()
			var param_type = typeof(p)
			
			
			
			print(param_name, str(param_type)) 

func _on_ConfirmEditLayer_pressed():
	hide()

func _on_EditLayerDialog_popup_hide():
	layer_being_edited = null
