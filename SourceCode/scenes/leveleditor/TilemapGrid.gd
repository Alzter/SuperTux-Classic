extends Node2D

onready var tile_selection = $SelectedTile

# Draws a grid for the currently selected tilemap,
# and sets the currently selected tile in the editor.

export var grid_color = Color(0,0,0,0.5)
var selected_tilemap = null
var selected_tile_position = Vector2()

func _ready():
	set_process(true)

func _process(delta):
	update()
	
	if selected_tilemap:
		var mouse_pos = get_global_mouse_position()
		selected_tile_position = selected_tilemap.world_to_map(mouse_pos)
		
		tile_selection.position = selected_tilemap.map_to_world(selected_tile_position)
		tile_selection.position += selected_tilemap.cell_size * 0.5

# Don't ask me how this works. Don't ask me why this works.

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
