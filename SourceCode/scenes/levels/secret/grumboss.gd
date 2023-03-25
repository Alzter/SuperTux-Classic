extends Node

onready var camera = get_parent().get_node("Camera2D")
onready var tilemap = get_parent().get_node("Shader/TileMap")

func _ready():
	pass

func _process(delta):
	camera.position.y += 64 * delta
	tilemap.position.y -= 64 * delta
