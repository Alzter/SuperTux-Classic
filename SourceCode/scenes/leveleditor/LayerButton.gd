extends Button

var layer_object = null
signal layer_button_pressed(button_node, layer_object)

func _on_LayerButton_pressed():
	emit_signal("layer_button_pressed", self, layer_object)
