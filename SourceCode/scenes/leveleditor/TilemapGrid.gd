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
	
	#global_position = tilemap.global_position
	
	var tilemap_rect = tilemap.get_used_rect()
	var tilemap_cell_size = tilemap.cell_size
	
	for y in range(0, tilemap_rect.size.y):
		draw_line(Vector2(0, y * tilemap_cell_size.y), Vector2(tilemap_rect.size.x * tilemap_cell_size.x, y * tilemap_cell_size.y), grid_color)

	for x in range(0, tilemap_rect.size.x):
		draw_line(Vector2(x * tilemap_cell_size.x, 0), Vector2(x * tilemap_cell_size.x, tilemap_rect.size.y * tilemap_cell_size.y), grid_color)
