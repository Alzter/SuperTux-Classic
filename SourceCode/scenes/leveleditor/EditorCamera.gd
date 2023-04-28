extends Camera2D

export var move_speed = 15


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func camera_to_player_position(player : KinematicBody2D):
	if !player: return
	
	position = player.position
	position.y = limit_top + ResolutionManager.window_resolution.y * 0.5

func _process(delta):
	var move_dir = Vector2()
	move_dir.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	move_dir.y = int(Input.is_action_pressed("duck")) - int(Input.is_action_pressed("move_up"))
	
	var velocity = move_dir * move_speed
	
	var edge_top = limit_top + ResolutionManager.window_resolution.y * 0.5
	var edge_left = limit_left + ResolutionManager.window_resolution.x * 0.5
	print(edge_top)
	
	position += velocity * delta * 60
	
	position.x = max(position.x, edge_left)
	position.y = clamp(position.y, edge_top, limit_bottom)
