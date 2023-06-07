extends PopupDialog

onready var layer_name = $VBoxContainer/PanelContainer/LayerProperties/NameEntry/Name
onready var layer_type = $VBoxContainer/PanelContainer/LayerProperties/TypeEntry/LayerTypes

export var default_layer_type = "TileMap"

# Don't show these layers in the Add layer dialog when editing levels
export var level_exclude_layers = ["ObjectContainer"]

# Don't show these layers in the Add layer dialog when editing worldmaps
export var worldmap_exclude_layers = ["ObjectMap"]

var current_layer_type = null

var is_in_worldmap = false

var layer_types = {}

func _on_AddLayerDialog_about_to_show():
	layer_name.clear()
	layer_type.clear()
	
	var exclude_layers = worldmap_exclude_layers if is_in_worldmap else level_exclude_layers
	
	var id = 0
	for type in owner.layer_types:
		if exclude_layers.has(type): continue
		
		var layer_icon_file = Global.layer_icons_directory + type + ".png"
		var layer_icon_texture = load(layer_icon_file)
		layer_type.add_icon_item(layer_icon_texture, type)
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

func _input(event):
	if !visible: return
	if Input.is_action_pressed("ui_accept"):
		yield(get_tree(), "idle_frame") # This has to be here or else the play level input registers too
		_on_AddLayerButton_pressed()
