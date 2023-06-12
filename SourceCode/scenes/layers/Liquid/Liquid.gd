extends Node2D

export var editor_params = ["height"]
export var height := 0.0 setget _set_height

var height_in_blocks = null setget, _get_height_in_blocks

onready var hitbox = get_node_or_null("KillBox")
onready var water_sprite = get_node_or_null("Appearance")
onready var lava_embers = get_node_or_null("LavaEmbers")
onready var lava_glow = get_node_or_null("LavaGlow")
onready var lava_glow_bg = get_node_or_null("LavaGlowBG")

onready var canvas_layers = [water_sprite, lava_embers]

func _ready():
	if height == 0 && position.y != 0:
		height = (float(position.y) / float(Global.TILE_SIZE)) * -1.0
	
	ResolutionManager.connect("window_resized", self, "window_resized")
	_set_height(height)
	
	if hitbox: hitbox.set_monitoring(true)

func _set_height(new_value):
	height = new_value
	
	if !canvas_layers: return
	
	position.y = self.height_in_blocks
	
	var existing_canvas_layers = []
	for node in canvas_layers: if node: existing_canvas_layers.append(node)
	
	for node in existing_canvas_layers:
		node.transform.origin.y = self.height_in_blocks
		if node == lava_embers: node.transform.origin.y += 192
		if node == lava_glow: node.transform.origin.y -= 32
		if node == lava_glow_bg: node.transform.origin.y -= 32

func window_resized():
	_set_height(height)

func _get_height_in_blocks():
	return height * Global.TILE_SIZE * -1.0

