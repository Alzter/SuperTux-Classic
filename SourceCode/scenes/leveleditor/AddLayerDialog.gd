extends PopupDialog

onready var layer_name = $VBoxContainer/NameEntry/Name
onready var layer_type = $VBoxContainer/TypeEntry/LayerTypes

func _on_AddLayerDialog_about_to_show():
	layer_name.clear()
	layer_type.clear()
	for type in owner.layer_types:
		layer_type.add_item(type)

func _on_AddLayerButton_pressed():
	var l_name = layer_name.text
	var l_type = layer_type.get_item_text(layer_type.get_selected())
	owner.add_layer(l_name, l_type)
	hide()
