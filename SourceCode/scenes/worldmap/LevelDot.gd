extends Node2D

onready var sprite = $AnimatedSprite

export var level_file_path = ""
export var level_cleared = false setget _update_cleared_state

export var is_teleporter = false
export var teleport_location = Vector2()

export var message = "" # Message that appears when standing on the level dot

export var invisible = false

export var extro_level_file_path = "" # Upon clearing the level, load into this level.


func _ready():
	sprite.visible = !invisible
	_update_sprite()

func _update_cleared_state(new_value):
	level_cleared = new_value if !is_teleporter else false
	_update_sprite()

func _update_sprite():
	if sprite == null: return
	if is_teleporter:
		sprite.animation = "teleporter"
	elif level_cleared:
		sprite.animation = "cleared"
	else:
		sprite.animation = "default"

func activate(player_position : Vector2, stop_direction : Vector2):
	if !is_teleporter:
		WorldmapManager.worldmap_player_position = player_position
		WorldmapManager.player_stop_direction = stop_direction
		WorldmapManager.worldmap_level = Global.current_level
		
		if extro_level_file_path != "":
			WorldmapManager.extro_level = extro_level_file_path
		else:
			WorldmapManager.extro_level = null
		
		Global.goto_level(level_file_path)
