extends Node2D

# This node is responsible for all tilemap functions,
# including placing and erasing tiles from the tilemap,
# displaying a grid for the currently selected tilemap, etc.

onready var tile_selection = $SelectedTile

export var grid_color = Color(0,0,0,0.5)
var selected_tilemap = null
var selected_tile_position = Vector2()
var current_tile_id = -1

var placing_tiles = false

var can_place_tiles = true

var level_boundaries = Rect2()

func _ready():
	set_process(true)

func update_level_boundaries(level : Node2D):
	level_boundaries = Rect2(Vector2.ZERO, Vector2.ONE * 999999999999999)
	if !level.is_worldmap:
		level_boundaries.end.y = level.level_height

func _process(delta):
	update()
	
	if selected_tilemap and owner.can_place_tiles:
		tile_selection.show()
		update_selected_tile()
	else:
		tile_selection.hide()
	
	if placing_tiles and owner.can_place_tiles:
		place_tile(selected_tilemap, selected_tile_position, current_tile_id)

func update_selected_tile():
	var mouse_pos = get_global_mouse_position()
	selected_tile_position = selected_tilemap.world_to_map(mouse_pos)
	tile_selection.visible = is_tile_position_legal(selected_tile_position)
	tile_selection.position = selected_tilemap.map_to_world(selected_tile_position)
	tile_selection.position += selected_tilemap.cell_size * 0.5

func _input(event):
	if selected_tilemap:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
				placing_tiles = event.pressed
				current_tile_id = 10 if event.button_index == BUTTON_LEFT else -1

# ===================================================================================
# Tile placement

func place_tile(tilemap : TileMap, tile_position : Vector2, tile_id : int, update_autotile = true, ignore_bounds = false):
	if !is_tile_position_legal(tile_position) and !ignore_bounds: return
	tilemap.set_cellv(tile_position, tile_id)
	if update_autotile: tilemap.update_bitmask_area(tile_position)
	
	# EDGE TILE HANDLING
	# If we draw a tile at the bottom of the tilemap, automatically fill it
	if tile_position.y == level_boundaries.end.y - 1:
		var fill_rect = Rect2(tile_position + Vector2.DOWN, Vector2(1, 30))
		fill_tile_rect(tilemap, fill_rect, tile_id, true, true)

func erase_tile(tilemap : TileMap, tile_position : Vector2, update_autotile = true):
	place_tile(tilemap, tile_position, -1, update_autotile)

func fill_tile_rect(tilemap : TileMap, rect : Rect2, tile_id : int, update_autotile = true, ignore_bounds = false):
	for y in rect.size.y:
		for x in rect.size.x:
			var tile_coords = rect.position + Vector2(x,y)
			place_tile(tilemap, tile_coords, tile_id, false, ignore_bounds)
	
	if update_autotile:
		tilemap.update_bitmask_region(rect.position, rect.end)

func erase_tile_rect(tilemap : TileMap, rect : Rect2, update_autotile = true):
	fill_tile_rect(tilemap, rect, -1, update_autotile)

func is_tile_position_legal(tile_position : Vector2):
	return level_boundaries.has_point(tile_position)

# =================================================================================
# DRAW GRID

# Draws a tile grid if a tilemap is selected.
func _draw():
	var tilemap = selected_tilemap
	if !tilemap: return
	
	var tilemap_rect = tilemap.get_used_rect()
	var tilemap_cell_size = tilemap.cell_size
	
	var zoom = Vector2(get_global_transform_with_canvas().x.x, get_global_transform_with_canvas().y.y)
	
	var edge_position = get_global_transform_with_canvas().origin / zoom
	edge_position -= Vector2(fmod(edge_position.x, tilemap_cell_size.x), fmod(edge_position.y, tilemap_cell_size.y))
	edge_position += tilemap_cell_size
	
	global_position = tilemap.global_position
	
	var res = ResolutionManager.window_size
	
	var y_end = edge_position.y + level_boundaries.end.y * tilemap_cell_size.y
	
	if y_end <= 0: return
	
	for y in range(0, ceil(res.y / tilemap_cell_size.y / zoom.y)):
		var y_global = y - (edge_position.y / tilemap_cell_size.y)
		if y_global > level_boundaries.end.y: break
		draw_line(Vector2(0, y * tilemap_cell_size.y) - edge_position, Vector2(res.x * tilemap_cell_size.x, y * tilemap_cell_size.y) - edge_position, grid_color)
	
	for x in range(0, ceil(res.x / tilemap_cell_size.x / zoom.x)):
		draw_line(Vector2(x * tilemap_cell_size.x, 0) - edge_position, Vector2(x * tilemap_cell_size.x, y_end) - edge_position, grid_color)
