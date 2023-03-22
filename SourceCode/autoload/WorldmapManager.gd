extends Node

var worldmap_level = null
var worldmap_player_position = null

var is_level_worldmap = false

var cleared_levels = []

func reset():
	worldmap_level = null
	worldmap_player_position = null
	is_level_worldmap = false
	cleared_levels = []

func add_current_level_to_cleared_levels():
	if Global.current_level == null:
		push_error("Error adding current level to cleared level list - Current level not known")
	
	cleared_levels.append(Global.current_level)

func return_to_worldmap(level_clear = false, save_game = false):
	if level_clear:
		add_current_level_to_cleared_levels()
	if save_game:
		SaveManager.save_game(cleared_levels, worldmap_level, worldmap_player_position)
	Global.goto_level(worldmap_level)
