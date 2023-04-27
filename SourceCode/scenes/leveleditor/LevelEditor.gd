extends Control

onready var level_to_load = "res://scenes/levels/world1/level1.tscn"

var level = null
var level_objects = null
var object_map = null

var selected_object = null

func _ready():
	get_tree().paused = true
	load_level_from_path(level_to_load)
	
	var tilemap = level_objects[2]
	place_tile(tilemap, Vector2(7,11), 10)

func place_tile(tilemap : TileMap, tile_position : Vector2, tile_id : int):
	tilemap.set_cellv(tile_position, tile_id)
	tilemap.update_bitmask_area(tile_position)

func erase_tile(tilemap : TileMap, tile_position : Vector2):
	place_tile(tilemap, tile_position, -1)

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
