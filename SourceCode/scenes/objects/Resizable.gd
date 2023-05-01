extends Control

onready var hitbox = get_node_or_null("StaticBody2D/CollisionShape2D")
onready var area = get_node_or_null("Area2D/CollisionShape2D")

export var hitbox_size_offset = Vector2.ZERO
export var hitbox_position_offset = Vector2.ZERO

func _ready():
	if !is_in_group("resizable"): add_to_group("resizable", true)
	
	_on_resized()

func _on_resized():
	var new_hitbox_size = rect_size * 0.5 + hitbox_size_offset
	var new_hitbox_position = rect_size * 0.5 + hitbox_position_offset
	
	if hitbox:
		hitbox.shape.set_deferred("extents", new_hitbox_size)
		hitbox.position = new_hitbox_position
	
	if area:
		area.shape.set_deferred("extents", new_hitbox_size)
		area.position = new_hitbox_position
