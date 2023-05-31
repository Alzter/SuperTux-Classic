extends Node2D

export var level_dots = [] # An array of all the level dot objects in the worldmap
export var tilemaps = []   # An array of all the tilemap objects in the worldmap

# The node of the level dot the player is currently standing on.
var current_level_dot = null setget set_current_level_dot

var state = 0
var sprite = null

onready var camera = $Camera2D

onready var sprite_big = $Control/SpriteBig
onready var sprite_small = $Control/SpriteSmall
onready var shader = $SpriteColour

onready var sfx = $SFX

var move_direction = Vector2(0,0)
var stop_direction = Vector2(0,0)

const MOVE_SPEED = 4 # Must be a power of 2 that's lower than 32

# PATH TILE BITMASK DETECTION
var up_tiles = [186, 146, 18, 58, 178, 154, 50, 26]
var down_tiles = [186, 146, 176, 152, 184, 178, 154, 144]
var left_tiles = [186, 56, 152, 26, 154, 58, 184, 24]
var right_tiles = [186, 56, 178, 58, 184, 48, 50, 176]

var corner_tiles = {
	50 : "ne",
	26 : "nw",
	152 : "se",
	176 : "sw",
}

var stop_tiles = [186]

# Set the player camera boundaries to the boundaries of the largest tilemap
func _ready():
	Global.player = self
	ResolutionManager.connect("window_resized", self, "window_resized")
	window_resized()
	if tilemaps == []: push_error("Worldmap player node cannot access any tilemaps in the worldmap")
	
	_populate_stop_tiles()
	
	state = Scoreboard.player_initial_state
	update_sprite_state()
	
	camera_bounds_to_tilemap_bounds()
	
	get_current_level_dot()

func _populate_stop_tiles():
	for tile in up_tiles:
		if (left_tiles.has(tile) or right_tiles.has(tile)) and !corner_tiles.has(tile):
			stop_tiles.append(tile)
	for tile in left_tiles:
		if (down_tiles.has(tile) or up_tiles.has(tile)) and !corner_tiles.has(tile):
			stop_tiles.append(tile)
	for tile in right_tiles:
		if (down_tiles.has(tile) or up_tiles.has(tile)) and !corner_tiles.has(tile):
			stop_tiles.append(tile)
	for tile in down_tiles:
		if (left_tiles.has(tile) or right_tiles.has(tile)) and !corner_tiles.has(tile):
			stop_tiles.append(tile)

func _process(delta):
	if tilemaps == []: push_error("Worldmap player node cannot access any tilemaps in the worldmap")
	
	for t in tilemaps:
		if !is_instance_valid(t): continue # Thanks for that.
		var tilemap : TileMap = t
		var tile_position = tilemap.world_to_map(position)
		var occupied_tile_id = tilemap.get_cellv(tile_position) # The ID of the tile the player is standing on.
		
		if occupied_tile_id != null and occupied_tile_id != -1:
			var tile_name = tilemap.get_tileset().tile_get_name(occupied_tile_id)
			
			if tile_name == "Path":
				handle_path_movement(tilemap, tile_position, occupied_tile_id)
				
				break
	
	position += MOVE_SPEED * move_direction
	
	update_sprite()
	
	if current_level_dot != null:
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
			var tile_position = tilemaps[0].world_to_map(position)
			Scoreboard.clear_message()
			current_level_dot.activate(self, tile_position, stop_direction)

func handle_path_movement(tilemap : TileMap, tile_position : Vector2, tile_id : int):
	# Get the autotile bitmask of the path tile the player is currently standing on.
	# We will use this for navigation.
	var tile_pos = tilemap.get_cell_autotile_coord(tile_position.x, tile_position.y)
	var bitmask = tilemap.get_tileset().autotile_get_bitmask(tile_id, tile_pos)
	
	var path_directions = []
	
	if bitmask in up_tiles: path_directions.append(Vector2.UP)
	if bitmask in left_tiles: path_directions.append(Vector2.LEFT)
	if bitmask in right_tiles: path_directions.append(Vector2.RIGHT)
	if bitmask in down_tiles: path_directions.append(Vector2.DOWN)
	
	# If the player is grid-aligned we can move
	var is_player_aligned_to_tile = tilemap.map_to_world(tile_position) + Vector2(16,16) == position
	if is_player_aligned_to_tile:
		if stop_tiles.has(bitmask):
			handle_leveldot_collisions(tilemap)
			move_direction = Vector2.ZERO
		
		var proposed_move_direction = get_move_input()
		
		handle_leveldot_collisions(tilemap)
		if path_directions.has(proposed_move_direction):
			var can_move = stop_direction == Vector2.ZERO or proposed_move_direction == stop_direction * -1
			if can_move:
				move_direction = proposed_move_direction
				stop_direction = Vector2.ZERO
		
		if move_direction != Vector2.ZERO:
			if corner_tiles.has(bitmask):
				match corner_tiles.get(bitmask):
					"ne":
						if move_direction == Vector2.LEFT: move_direction = Vector2.UP
						if move_direction == Vector2.DOWN: move_direction = Vector2.RIGHT
					"nw":
						if move_direction == Vector2.RIGHT: move_direction = Vector2.UP
						if move_direction == Vector2.DOWN: move_direction = Vector2.LEFT
					"se":
						if move_direction == Vector2.UP: move_direction = Vector2.LEFT
						if move_direction == Vector2.RIGHT: move_direction = Vector2.DOWN
					"sw":
						if move_direction == Vector2.UP: move_direction = Vector2.RIGHT
						if move_direction == Vector2.LEFT: move_direction = Vector2.DOWN
		
		if !path_directions.has(move_direction): move_direction = Vector2.ZERO

func get_move_input():
	var move_direction = Vector2.ZERO
	if Input.is_action_just_pressed("move_left"): move_direction = Vector2.LEFT
	if Input.is_action_just_pressed("move_right"): move_direction = Vector2.RIGHT
	if Input.is_action_just_pressed("move_up"): move_direction = Vector2.UP
	if Input.is_action_just_pressed("duck"): move_direction = Vector2.DOWN
	return move_direction

func camera_bounds_to_tilemap_bounds():
	for t in tilemaps:
		var tilemap : TileMap = t
		var bounds = tilemap.get_used_rect()
		bounds = Rect2(bounds.position * 32, bounds.size * 32)
		
		camera.limit_left = min(bounds.position.x, camera.limit_left)
		camera.limit_right = max(bounds.end.x, camera.limit_right)
		camera.limit_top = min(camera.limit_top, bounds.position.y)
		camera.limit_bottom = max(camera.limit_bottom, bounds.end.y)

func handle_leveldot_collisions(tilemap):
	if move_direction == Vector2.ZERO: return
	if stop_direction != Vector2.ZERO:
		if move_direction == stop_direction * -1: return
	
	var new_level_dot = null
	
	for leveldot in level_dots:
		var level_position = tilemap.world_to_map(leveldot.position)
		var player_position = tilemap.world_to_map(position)
		
		if level_position == player_position:
			new_level_dot = leveldot
			
			if !leveldot.level_cleared:
				stop_direction = move_direction
				move_direction = Vector2.ZERO
				break
			else:
				move_direction = Vector2.ZERO
				break
	
	self.current_level_dot = new_level_dot

func get_current_level_dot(tilemap = tilemaps[0]):
	for leveldot in level_dots:
		var level_position = tilemap.world_to_map(leveldot.position)
		var player_position = tilemap.world_to_map(position)
		
		if level_position == player_position:
			set_current_level_dot(leveldot, false)
			return

func update_sprite_state(state = self.state):
	sprite_big.visible = (state == 0)
	sprite_small.visible = (state != 0)
	sprite = sprite_big if (state == 0) else sprite_small
	
	if state > 1:
		shader.play("red")
	else:
		shader.play("black")

func set_current_level_dot(new_value, sound = true):
	if current_level_dot == new_value: return
	current_level_dot = new_value
	
	Scoreboard.clear_message()
	
	if new_value:
		if current_level_dot.message != "":
			Scoreboard.display_message(current_level_dot.message)
		
		elif current_level_dot.level_file_path != "":
			var level_path = current_level_dot.level_file_path
			var level_name = Global.get_level_attribute(level_path, "level_title")
			Scoreboard.display_message(level_name)
		
		if sound: sfx.play("LevelDot")

func update_sprite():
	if move_direction == Vector2.ZERO:
		sprite.play("default")
	else:
		sprite.play("walk")

func window_resized():
	camera.zoom = Vector2(1,1)
	var window_resolution = ResolutionManager.window_resolution
	if window_resolution == null: return
	
	for tilemap in tilemaps:
		var bounds = tilemap.get_used_rect()
		bounds = Rect2(bounds.position * 32, (bounds.end - Vector2.ONE * 2) * 32)
		var tilemap_size = (bounds.end - bounds.position)
		#print(window_resolution, tilemap_size)
		
		if tilemap_size.x < window_resolution.x or tilemap_size.y < window_resolution.y:
			camera.zoom = Vector2(0.5, 0.5)

func set_position(new_value):
	var grid_pos = new_value / Global.TILE_SIZE
	grid_pos = Vector2(floor(grid_pos.x), floor(grid_pos.y))
	
	var grid_aligned_pos = grid_pos * Global.TILE_SIZE + Vector2.ONE * Global.TILE_SIZE * 0.5
	.set_position(grid_aligned_pos)
