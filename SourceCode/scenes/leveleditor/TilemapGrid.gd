extends Node2D

# This node is responsible for all tilemap functions,
# including placing and erasing tiles from the tilemap,
# displaying a grid for the currently selected tilemap, etc.

onready var tile_selection = $SelectedTile

export var grid_color = Color(0,0,0,0.5)
var selected_tilemap = null
var selected_tile_position = Vector2()

func _ready():
	set_process(true)

func _process(delta):
	update()
	
	if selected_tilemap:
		tile_selection.show()
		update_selected_tile()
	else:
		tile_selection.hide()

func update_selected_tile():
	var mouse_pos = get_global_mouse_position()
	selected_tile_position = selected_tilemap.world_to_map(mouse_pos)
	tile_selection.position = selected_tilemap.map_to_world(selected_tile_position)
	tile_selection.position += selected_tilemap.cell_size * 0.5

func _input(event):
	if selected_tilemap:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				place_tile(selected_tilemap, selected_tile_position, 10)

# ===================================================================================
# Tile placement

func place_tile(tilemap : TileMap, tile_position : Vector2, tile_id : int, update_autotile = true):
	tilemap.set_cellv(tile_position, tile_id)
	if update_autotile: tilemap.update_bitmask_area(tile_position)

func erase_tile(tilemap : TileMap, tile_position : Vector2, update_autotile = true):
	place_tile(tilemap, tile_position, -1, update_autotile)

func fill_tile_rect(tilemap : TileMap, rect : Rect2, tile_id : int, update_autotile = true):
	for y in rect.size.y:
		for x in rect.size.x:
			var tile_coords = rect.position + Vector2(x,y)
			place_tile(tilemap, tile_coords, tile_id, false)
	
	if update_autotile:
		tilemap.update_bitmask_region(rect.position, rect.end)

func erase_tile_rect(tilemap : TileMap, rect : Rect2, update_autotile = true):
	fill_tile_rect(tilemap, rect, -1, update_autotile)


# =================================================================================
# DRAW GRID

# Draws a tile grid if a tilemap is selected.
func _draw():
	var tilemap = selected_tilemap
	if !tilemap: return
	
	var tilemap_rect = tilemap.get_used_rect()
	var tilemap_cell_size = tilemap.cell_size
	
	var zoom = Vector2(get_global_transform_with_canvas().x.x, get_global_transform_with_canvas().y.y)
	
	var edge_position = get_global_transform_with_canvas().origin * ResolutionManager.screen_shrink / zoom
	edge_position -= Vector2(fmod(edge_position.x, tilemap_cell_size.x), fmod(edge_position.y, tilemap_cell_size.y))
	edge_position += tilemap_cell_size
	
	global_position = tilemap.global_position
	
	var res = ResolutionManager.window_size
	
	for y in range(0, ceil(res.y / tilemap_cell_size.y / zoom.y)):
		draw_line(Vector2(0, y * tilemap_cell_size.y) - edge_position, Vector2(res.x * tilemap_cell_size.x, y * tilemap_cell_size.y) - edge_position, grid_color)

	for x in range(0, ceil(res.x / tilemap_cell_size.x / zoom.x)):
		draw_line(Vector2(x * tilemap_cell_size.x, 0) - edge_position, Vector2(x * tilemap_cell_size.x, res.y * tilemap_cell_size.y) - edge_position, grid_color)
