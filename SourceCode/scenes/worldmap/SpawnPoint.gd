extends Node2D

onready var sprite = $Sprite

func _ready():
	sprite.visible = true
	
	Global.connect("level_ready", self, "start_level")
	
	set_spawn_position()

# Spawn points are not visible when inside the worldmap, only in the editor
func start_level():
	sprite.hide()

func set_position(value : Vector2):
	position = value
	set_spawn_position()
	
	print("Set player spawn position")

func set_spawn_position():
	var level = Global.current_level
	if level:
		if !is_instance_valid(level): return
		
		if level.get("spawn_position") != null:
			level.spawn_position = get_tile_position()

func get_tile_position() -> Vector2:
	var tile_pos = (global_position / Global.TILE_SIZE)
	tile_pos = Vector2(floor(tile_pos.x), floor(tile_pos.y))
	return tile_pos
