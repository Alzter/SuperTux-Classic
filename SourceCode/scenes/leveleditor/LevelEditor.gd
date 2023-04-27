extends Control

export var level_to_load = "res://scenes/levels/world1/level1.tscn"

var level = null
var level_objects = null
var object_map = null

var selected_object = null

func _ready():
	get_tree().paused = true
	load_level_from_path(level_to_load)
	
	var tilemap = level_objects[2]
	place_tile(tilemap, Vector2(7,11), 10)
	
	var tile_rect = Rect2(Vector2(4,4), Vector2(4,4))
	fill_tile_rect(tilemap, tile_rect, 10)

# ===================================================================================
# Tile placement

func fill_tile_rect(tilemap : TileMap, rect : Rect2, tile_id : int, update_autotile = true):
	place_tile(tilemap, rect.position, tile_id)

func place_tile(tilemap : TileMap, tile_position : Vector2, tile_id : int, update_autotile = true):
	tilemap.set_cellv(tile_position, tile_id)
	if update_autotile: tilemap.update_bitmask_area(tile_position)

func erase_tile(tilemap : TileMap, tile_position : Vector2):
	place_tile(tilemap, tile_position, -1)

# ==================================================================================
# Level loading

func load_level_from_path(level_path: String):
	var level_object = load(level_path).instance()
	load_level_from_object(level_object)

func load_level_from_object(level_object: Node2D):
	add_child(level_object)
	level_object.set_owner(self)
	update_level_variables(level_object)

func update_level_variables(level_object):
	level = level_object
	level_objects = level_object.get_children()
	object_map = null
	for node in level_objects:
		if node.is_in_group("objectmaps"):
			object_map = node
			return
