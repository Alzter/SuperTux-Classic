extends Node2D

# Draws a grid for the currently selected tilemap

export var grid_color = Color(0,0,0,0.5)
var selected_tilemap = null

func _ready():
	set_process(true)

func _process(delta):
	update()

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
	
	print(edge_position)
	
	var res = ResolutionManager.window_size
	
	for y in range(0, ceil(res.y / tilemap_cell_size.y / zoom.y)):
		draw_line(Vector2(0, y * tilemap_cell_size.y) - edge_position, Vector2(res.x * tilemap_cell_size.x, y * tilemap_cell_size.y) - edge_position, grid_color)

	for x in range(0, ceil(res.x / tilemap_cell_size.x / zoom.x)):
		draw_line(Vector2(x * tilemap_cell_size.x, 0) - edge_position, Vector2(x * tilemap_cell_size.x, res.y * tilemap_cell_size.y) - edge_position, grid_color)
