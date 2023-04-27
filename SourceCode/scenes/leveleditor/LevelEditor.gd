extends Node

export var level_to_load = "res://scenes/levels/world1/level1.tscn"

export var cache_level_directory = "user://leveleditor/"
export var cache_level_filename = "cache.tscn"

onready var ui_scale = get_node_or_null("UI/Scale")
onready var ui_editor = get_node_or_null("UI/Scale/EditorUI")

onready var cache_level_path = cache_level_directory + cache_level_filename

var level = null
var level_objects = null
var object_map = null

var selected_object = null

var edit_mode = true

func _ready():
	Scoreboard.hide()
	ResolutionManager.connect("window_resized", self, "window_resized")
	window_resized()
	
	load_level_from_path(level_to_load)
	
	var tile = 10
	
	var tilemap = level_objects[2]
	place_tile(tilemap, Vector2(7,11), tile)
	
	var tile_rect = Rect2(Vector2(4,4), Vector2(4,4))
	fill_tile_rect(tilemap, tile_rect, tile)

# =================================================================
# Toggle Edit Mode

func toggle_edit_mode():
	if edit_mode:
		enter_play_mode()
	else:
		enter_edit_mode()

func enter_play_mode():
	if !level: return
	create_level_cache()
	if ui_editor: ui_editor.hide()
	level.start_level(false)
	edit_mode = false

func enter_edit_mode():
	if !level: return
	load_level_from_path(cache_level_path)
	Scoreboard.hide()
	if ui_editor: ui_editor.show()
	edit_mode = true
	Music.stop_all()

# ===================================================================================
# Tile placement

func fill_tile_rect(tilemap : TileMap, rect : Rect2, tile_id : int, update_autotile = true):
	for y in rect.size.y:
		for x in rect.size.x:
			var tile_coords = rect.position + Vector2(x,y)
			place_tile(tilemap, tile_coords, tile_id, false)
	
	if update_autotile:
		tilemap.update_bitmask_region(rect.position, rect.end)

func erase_tile_rect(tilemap : TileMap, rect : Rect2, update_autotile = true):
	fill_tile_rect(tilemap, rect, -1, update_autotile)

func place_tile(tilemap : TileMap, tile_position : Vector2, tile_id : int, update_autotile = true):
	tilemap.set_cellv(tile_position, tile_id)
	if update_autotile: tilemap.update_bitmask_area(tile_position)

func erase_tile(tilemap : TileMap, tile_position : Vector2, update_autotile = true):
	place_tile(tilemap, tile_position, -1, update_autotile)

# ==================================================================================
# Level loading

func load_level_from_path(level_path: String):
	var level_object = load(level_path).instance()
	load_level_from_object(level_object)

func load_level_from_object(level_object: Node2D):
	if level:
		level.queue_free()
		yield(level, "tree_exited")
	
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

func create_level_cache():
	var dir = Directory.new()
	dir.make_dir_recursive(cache_level_directory)
	Global.save_node_to_directory(level, cache_level_path)

func set_ui_scale(scale):
	ui_scale.rect_scale = Vector2.ONE * scale
	ui_scale.anchor_bottom = 1 / scale
	ui_scale.anchor_right = 1 / scale

func _on_EditToggle_pressed():
	toggle_edit_mode()

func window_resized():
	var scale = min(ResolutionManager.window_size.x / 1000.0, ResolutionManager.window_size.y / 500.0)
	print(scale)
	scale = min(scale, 1)
	set_ui_scale(scale)
