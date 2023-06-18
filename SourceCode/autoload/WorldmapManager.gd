extends Node

var worldmap_level = null setget _update_worldmap_level_file
var worldmap_player_position = null
var player_stop_direction = null

var is_level_worldmap = false

var extro_level = null

var cleared_levels = []

var worldmap_name = null

func reset():
	worldmap_level = null
	worldmap_name = null
	worldmap_player_position = null
	is_level_worldmap = false
	cleared_levels = []
	player_stop_direction = null
	extro_level = null

func add_current_level_to_cleared_levels():
	if Global.current_level_path == null:
		push_error("Error adding current level to cleared level list - Current level not known")
	
	cleared_levels.append(Global.current_level_path)

func save_progress(level_clear = false, save_game = true):
	if level_clear:
		player_stop_direction = null
		add_current_level_to_cleared_levels()
	if save_game:
		SaveManager.save_game(worldmap_name, cleared_levels, worldmap_level, worldmap_player_position)

func return_to_worldmap(level_clear = false, save_game = false):
	save_progress(level_clear, save_game)
	Global.goto_level(worldmap_level)

func _update_worldmap_level_file(new_value):
	worldmap_level = new_value
	
	# Set "worldmap name" to the name of the folder the worldmap file is located in.
	# E.g. for "res://scenes/levels/world1/worldmap.tscn" the folder name is "world1"
	worldmap_name = worldmap_level.get_base_dir().split("/")[-1]
