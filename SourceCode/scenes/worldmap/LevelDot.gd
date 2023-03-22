extends Node2D

onready var sprite = $AnimatedSprite

export var level = ""
export var cleared = false setget _update_cleared_state

func _update_cleared_state(new_value):
	cleared = new_value
	if cleared:
		sprite.animation = "cleared"
	else:
		sprite.animation = "default"
