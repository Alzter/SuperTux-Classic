extends Button

onready var layer_options = $LayerOptions

var layer_object = null
signal layer_button_pressed(button_node, layer_object)
signal edit_layer(layer_object)
signal delete_layer(layer_object)

func _ready():
	layer_options.hide()

func _on_LayerButton_pressed():
	emit_signal("layer_button_pressed", self, layer_object)

func _on_LayerButton_mouse_entered():
	layer_options.show()

func _on_LayerButton_mouse_exited():
	layer_options.hide()

func _on_Edit_pressed():
	emit_signal("edit_layer", layer_object)

func _on_Delete_pressed():
	emit_signal("delete_layer", layer_object)

# RIGHT CLICKING THE LAYER BUTTON ACTIVATES THE EDIT LAYER DIALOG
func _on_LayerButton_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_RIGHT:
			_on_Edit_pressed()
