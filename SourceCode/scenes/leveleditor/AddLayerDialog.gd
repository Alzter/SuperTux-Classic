extends PopupDialog

onready var layer_name = $VBoxContainer/NameEntry/Name
onready var layer_type = $VBoxContainer/TypeEntry/LayerTypes

export var default_layer_type = "TileMap"

var current_layer_type = null

var layer_types = {}

func _on_AddLayerDialog_about_to_show():
	layer_name.clear()
	layer_type.clear()
	
	var id = 0
	for type in owner.layer_types:
		layer_type.add_item(type)
		layer_types[type] = id
		id += 1
	
	if current_layer_type:
		_select_layer_type(current_layer_type)
	else:
		if default_layer_type:
			_select_layer_type(default_layer_type)
			current_layer_type = default_layer_type
		else:
			current_layer_type = layer_type.get_item_text(layer_type.get_selected())
	
	layer_name.text = current_layer_type

func _on_AddLayerButton_pressed():
	var l_name = layer_name.text
	var l_type = layer_type.get_item_text(layer_type.get_selected())
	
	owner.add_layer(l_name, l_type)
	hide()

func _select_layer_type(type_name : String):
	var item_id = layer_types.get(type_name)
	if item_id:
		layer_type.select(item_id)

func _on_LayerTypes_item_selected(index):
	var new_type = layer_type.get_item_text(index)
	
	if layer_name.text == current_layer_type:
		layer_name.text = new_type
	
	current_layer_type = new_type
