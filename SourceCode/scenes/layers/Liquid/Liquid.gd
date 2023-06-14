extends Node2D

export var editor_params = ["height", "multiply_color", "overlay_color", "in_front"]
export var height := 2.5 setget _set_height

onready var multiply_color : Color = modulate setget _update_multiply_color
var overlay_color : Color = Color(0.5,0.5,0.5,0.5) setget _update_overlay_color

var height_in_blocks = null setget, _get_height_in_blocks

export var in_front = true setget _set_in_front

onready var hitbox = get_node_or_null("KillBox")
onready var water_layer = get_node_or_null("Appearance/ParallaxLayer")
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
	
	if water_layer:
		
		if water_layer.material:
			get_overlay_color(water_layer.material)
	
	elif material:
		get_overlay_color(material)
	
	_update_multiply_color(multiply_color)

func get_overlay_color(material):
	var overlay = material.get_shader_param("overlay_color")
	
	if overlay is Plane:
		overlay_color = Color(overlay.x, overlay.y, overlay.z, overlay.d)
	else:
		overlay_color = overlay

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

func _update_multiply_color(new_value):
	multiply_color = new_value
	modulate = multiply_color
	if water_layer: water_layer.modulate = multiply_color

func _update_overlay_color(new_value):
	overlay_color = new_value
	
	var overlay_plane = Plane(overlay_color.r, overlay_color.g, overlay_color.b, overlay_color.a)
	
	if water_layer:
		if water_layer.material:
			water_layer.material.set_shader_param("overlay_color", overlay_plane)
	elif material:
		material.set_shader_param("overlay_color", overlay_plane)

func _set_in_front(new_value):
	in_front = new_value
	z_index = 300 if in_front else -300
	if water_sprite:
		water_sprite.layer = 100 if in_front else -80
