extends Node2D

# This node is responsible for all tilemap functions,
# including placing and erasing tiles from the tilemap,
# displaying a grid for the currently selected tilemap, etc.

onready var tile_selection = $SelectedTile
onready var tile_preview = $SelectedTile/TilePreview

export var grid_color = Color(0,0,0,0.5)
export var rect_select_add_color = Color(0.1, 1, 0.1, 0.4)
export var rect_select_erase_color = Color(1, 0.1, 0.1, 0.4)


var selected_tilemap = null
var selected_tile_position = Vector2()
var old_selected_tile_position = Vector2()
var tile_id_to_use = -1

var placing_tiles = false
var placing_rectangle_fill = false # If the user is making a rectangular fill of tiles
var is_erasing = false

var using_eyedropper = false

var rect_fill_origin = Vector2()

var level_boundaries = Rect2()

var rect_selection = Rect2()

var mouse_over_ui = false

func _ready():
	set_process(true)

func update_level_boundaries(level : Node2D):
	level_boundaries = Rect2(Vector2.ZERO, Vector2.ONE * 999999999999999)
	if !level.is_worldmap:
		level_boundaries.end.y = level.level_height

func _process(delta):
	update()
	
	tile_selection.hide()
	
	if !owner.can_place_tiles: return
	
	if !placing_tiles and mouse_over_ui: return
	
	if selected_tilemap:
		if is_instance_valid(selected_tilemap):
			selected_tile_position = get_selected_tile()
			
			if using_eyedropper:
				var eyedrop_tile_id = selected_tilemap.get_cellv(selected_tile_position)
				
				if eyedrop_tile_id == -1: # You can't eyedrop air
					using_eyedropper = false
					return
				
				owner.current_tile_id = eyedrop_tile_id
				
				var tile_is_flipped = selected_tilemap.is_cell_x_flipped(selected_tile_position.x, selected_tile_position.y)
				
				owner.flip_tiles_enabled = tile_is_flipped
				
				owner.eyedropper_enabled = false
				using_eyedropper = false
				
				owner.play_sound("Eyedrop")
			
			if !placing_rectangle_fill:
				tile_selection.show()
				
				tile_preview.visible = !owner.eraser_enabled and !owner.eyedropper_enabled
				tile_preview.flip_h = owner.flip_tiles_enabled
				update_tile_selected_sprite()
	
			
			var is_tile_new = old_selected_tile_position != selected_tile_position
			
			if placing_tiles and is_tile_new:
				play_tile_sound(selected_tilemap, tile_id_to_use, selected_tile_position)
				
				if placing_rectangle_fill:
					rect_selection = Rect2(rect_fill_origin, Vector2.ZERO).expand(selected_tile_position)
					fill_tile_rect(selected_tilemap, rect_selection, tile_id_to_use)
				else:
					place_tile(selected_tilemap, selected_tile_position, tile_id_to_use)
			
			old_selected_tile_position = selected_tile_position

func get_selected_tile():
	var mouse_pos = get_global_mouse_position()
	return selected_tilemap.world_to_map(mouse_pos)

func update_tile_selected_sprite():
	tile_selection.visible = is_tile_position_legal(selected_tile_position)
	tile_selection.position = selected_tilemap.map_to_world(selected_tile_position)
	tile_selection.position += selected_tilemap.cell_size * 0.5

func _input(event):
	if !owner.can_place_tiles: return
	
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		mouse_over_ui = owner.mouse_over_ui or Global.is_popup_visible()
	
	if selected_tilemap:
		if event is InputEventMouseButton:
			if event.pressed and mouse_over_ui: return
			
			var about_to_use_eyedropper = event.button_index == BUTTON_MIDDLE or Input.is_action_pressed("editor_eyedrop_tool") or owner.eyedropper_enabled
			
			if !about_to_use_eyedropper:
				placing_tiles = event.pressed
				
				if placing_tiles:
					owner.add_undo_state()
					old_selected_tile_position = Vector2.ZERO - Vector2.ONE
				
				placing_rectangle_fill = false
				
				is_erasing = event.button_index == BUTTON_RIGHT or owner.eraser_enabled
				tile_id_to_use = owner.current_tile_id if !is_erasing else -1
				
				var can_rect_fill = owner.rect_select_enabled or Input.is_action_pressed("editor_rect_select")
				
				if can_rect_fill and placing_tiles:
					var rect_start = get_selected_tile()
					rect_fill_origin = rect_start
					placing_rectangle_fill = true
			else:
				if !event.pressed:
					using_eyedropper = true

# ===================================================================================
# Tile placement

func place_tile(tilemap : TileMap, tile_position : Vector2, tile_id : int, update_autotile = true, ignore_bounds = false):
	if !is_tile_position_legal(tile_position) and !ignore_bounds: return
	
	var flip_horizontally = owner.flip_tiles_enabled# or Input.is_action_pressed("editor_flip_tiles")
	
	tilemap.set_cellv(tile_position, tile_id, flip_horizontally)
	
	# Tilemaps in STC have custom properties which we use here.
	if tilemap.is_in_group("stc_tilemaps"):
		
		# Tilemaps in STC have some tiles which don't apply autotile rules.
		# If this tile is one of those, don't apply autotile rules.
		if !tilemap.get_autotile_status(tile_id): update_autotile = false
	
	if update_autotile: tilemap.update_bitmask_area(tile_position)
	
	if tilemap.is_in_group("stc_tilemaps"):
		tilemap.apply_custom_autotile_rules(tile_position)
	
	# EDGE TILE HANDLING - EXPAND
	# If we draw a tile at the bottom of the tilemap, automatically fill it
	if tilemap.get("expand_on_bottom"):
		if tile_position.y == level_boundaries.end.y - 1:
			var fill_rect = Rect2(tile_position + Vector2.DOWN, Vector2.DOWN * 30)
			fill_tile_rect(tilemap, fill_rect, tile_id, true, true)

func erase_tile(tilemap : TileMap, tile_position : Vector2, update_autotile = true):
	place_tile(tilemap, tile_position, -1, update_autotile)

func fill_tile_rect(tilemap : TileMap, rect : Rect2, tile_id : int, update_autotile = true, ignore_bounds = false):
	for y in rect.size.y + 1:
		for x in rect.size.x + 1:
			var tile_coords = rect.position + Vector2(x,y)
			place_tile(tilemap, tile_coords, tile_id, false, ignore_bounds)
	
	if tilemap.is_in_group("stc_tilemaps"):
		if !tilemap.get_autotile_status(tile_id): update_autotile = false
	
	if update_autotile:
		if rect.size != Vector2.ZERO:
			tilemap.update_bitmask_region(rect.position, rect.end)
		else:
			tilemap.update_bitmask_area(rect.position)

func erase_tile_rect(tilemap : TileMap, rect : Rect2, update_autotile = true):
	fill_tile_rect(tilemap, rect, -1, update_autotile)

func is_tile_position_legal(tile_position : Vector2):
	return level_boundaries.has_point(tile_position)

func stop_placing_tiles():
	placing_tiles = false
	placing_rectangle_fill = false

# =================================================================================
# DRAW GRID

# Draws a tile grid if a tilemap is selected.
func _draw():
	var tilemap = selected_tilemap
	if !tilemap: return
	if !is_instance_valid(tilemap): return
	if owner.ui_editor:
		if !owner.ui_editor.visible: return
	
	draw_tilemap_grid(tilemap)
	if placing_rectangle_fill:
		var rect = Rect2(rect_selection.position * tilemap.cell_size, (rect_selection.size + Vector2.ONE) * tilemap.cell_size)
		var rect_color = rect_select_erase_color if is_erasing else rect_select_add_color
		draw_rect(rect, rect_color, true)

func draw_tilemap_grid(tilemap : TileMap):
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

# ========================================================================================

func play_tile_sound(selected_tilemap, tile_id, selected_tile_position):
	if selected_tilemap.get_cellv(selected_tile_position) == tile_id_to_use: return
	
	if selected_tilemap.is_in_group("objectmaps"):
		if tile_id == -1: owner.play_sound("EraseObject")
		else: owner.play_sound("PlaceObject")
	else:
		if tile_id == -1: owner.play_sound("EraseTile")
		else: owner.play_sound("PlaceTile")
