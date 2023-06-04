extends Button

onready var label = $Label
onready var layer_options = $LayerOptions

export var button_font : Font

var layer_object = null
var layer_name = null setget _set_layer_name

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

func _set_layer_name(new_value):
	layer_name = new_value
	label.text = new_value
	
	
	# We have to manually shrink the text for the label of the layer if it gets too long
	var text_size = button_font.get_string_size(label.text).x
	
	var max_size = rect_min_size.x - label.margin_left + label.margin_right
	
	if text_size > max_size:
		
		var new_size = Vector2.ONE * max_size / text_size
		label.rect_scale = new_size
	
	else: label.rect_scale = Vector2.ONE
