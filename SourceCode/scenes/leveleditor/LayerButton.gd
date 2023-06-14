extends Button

onready var label = $Label
onready var layer_options = $LayerOptions
onready var layer_icon = $LayerIcon

export var button_font : Font

export var uneditable_style_box : StyleBox
export var editable_layer_types = ["TileMap", "ObjectMap", "ObjectContainer"]

var layer_object = null setget _set_layer_object
var layer_name = null setget _set_layer_name

var layer_type = null setget , _get_layer_type

signal layer_button_pressed(button_node, layer_object)
signal edit_layer(layer_object)
signal delete_layer(layer_object)

func _ready():
	layer_options.hide()
	set_disabled(false)

func _on_LayerButton_pressed():
	#print(self.layer_type)
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
		if event.button_index == BUTTON_LEFT:
			_on_LayerButton_pressed()
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

func _set_layer_object(new_value):
	if new_value == layer_object: return
	layer_object = new_value
	
	_update_layer_icon()

func _get_layer_type():
	if !layer_object: return null
	if !is_instance_valid(layer_object): return null
	return layer_object.filename.get_file().trim_suffix(".tscn")

func _update_layer_icon():
	if !self.layer_type: return
	if !Global.get("layer_icons_directory"): return
	var layer_icon_img = Global.layer_icons_directory + self.layer_type + ".png"
	
	#print(layer_icon_img)
	
	layer_icon.texture = load(layer_icon_img)
	
	if !editable_layer_types.has(self.layer_type):
		add_stylebox_override("normal", uneditable_style_box)

func set_disabled(value):
	disabled = value
	layer_icon.modulate.a = 1 if disabled else 0.5
	label.modulate = Color(0,0.67,1) if disabled else Color(1,1,1)
