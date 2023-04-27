extends Control

onready var level = get_node_or_null("Level")

func _ready():
	get_tree().paused = true
