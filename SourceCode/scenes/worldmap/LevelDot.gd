extends Node2D

onready var sprite = $AnimatedSprite
onready var sfx = $SFX

export var level_file_path = "[LevelPath]"
export var level_cleared = false setget _update_cleared_state

export var is_teleporter = false
export var teleport_location = Vector2()

export var message = "" # Message that appears when standing on the level dot

export var invisible = false

export var extro_level_file_path = "[LevelPath]" # Upon clearing the level, load into this level.

export var editor_params = ["level_file_path", "message", "invisible"]

func _ready():
	if Global.is_in_editor: level_cleared = true
	
	_update_cleared_state(level_cleared)

func _update_cleared_state(new_value):
	if is_teleporter or invisible: level_cleared = true
	else: level_cleared = new_value
	_update_sprite()

func _update_sprite():
	if sprite == null: return
	sprite.visible = !invisible
	if is_teleporter:
		sprite.animation = "teleporter"
	elif level_cleared:
		sprite.animation = "cleared"
	else:
		sprite.animation = "default"

func activate(player, player_position : Vector2, stop_direction : Vector2):
	if is_teleporter:
		sfx.play("Warp")
		player.position = teleport_location * 32 + Vector2(16,16)
		return
	
	elif level_file_path != "":
		if level_file_path == Global.empty_level_path_string: return
		
		# Don't play the level if we're in the editor
		if Global.is_in_editor: return
		
		# Don't play the level if the file path doesn't point to a level
		if !Global.string_is_scene_path(level_file_path): return
		
		WorldmapManager.worldmap_player_position = player_position
		WorldmapManager.player_stop_direction = stop_direction
		WorldmapManager.worldmap_level = Global.current_level_path
		
		if extro_level_file_path != "" and extro_level_file_path != Global.empty_level_path_string:
			WorldmapManager.extro_level = extro_level_file_path
		else:
			WorldmapManager.extro_level = null
		
		Global.goto_level(level_file_path)
