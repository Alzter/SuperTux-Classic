extends Camera2D

export var move_speed = 16.0
export var mouse_drag_strength = 1.0
export var mouse_zoom_speed = 0.1

export var min_zoom = (1.0 / 4.0) # 400% zoom in
export var max_zoom = (1.0 * 1.5) # 66% zoom out

export var touch_zoom_speed = 0.05
export var touch_zoom_sensitivity = 50 # Minimum number of pixels needed to start a zoom

var mouse_motion = Vector2.ZERO
var mouse_dragging_camera = false
var mouse_drag_pressed = false

var touch_dragging_camera = false

var dragging_camera = null setget , _is_dragging_camera

var touch_events = {} setget update_touch_events
var last_drag_distance = 0

var cam_zoom = null setget , _get_global_camera_zoom

onready var tux_sprite = get_node("TuxSprite")

# Override base set zoom function to impose zoom limits
func set_zoom(new_zoom : Vector2):
	new_zoom = Vector2(
		clamp(new_zoom.x, min_zoom, max_zoom),
		clamp(new_zoom.y, min_zoom, max_zoom)
	)
	
	.set_zoom(new_zoom)

# Touchscreen can drag/zoom camera using two fingers.
# Code credit: https://kidscancode.org/godot_recipes/3.x/2d/touchscreen_camera/index.html
func handle_touchscreen_input(event : InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			self.touch_events[event.index] = event
		else:
			self.touch_events.erase(event.index)

	if event is InputEventScreenDrag:
		self.touch_events[event.index] = event
		
		if touch_events.size() == 2:
			
			# Calculate the drag motion of the two-fingure drag gesture
			# by getting the movement (in px) of each finger and averaging them.
			var drag_relative_1 = touch_events[0].relative
			var drag_relative_2 = touch_events[1].relative
			
			# Use this to move the camera.
			var touch_drag_motion = Vector2(
				(drag_relative_1.x + drag_relative_2.x) * -0.5,
				(drag_relative_1.y + drag_relative_2.y) * -0.5
			)
			
			position += touch_drag_motion
			
			# If we're using a pinch gesture, zoom the camera
			var drag_distance = touch_events[0].position.distance_to(touch_events[1].position)
			
			var zoom_motion = drag_distance - last_drag_distance
			
			var can_drag_camera = abs(zoom_motion) > touch_zoom_sensitivity
			
			if can_drag_camera:
				
				var new_zoom = (1 + touch_zoom_speed) if drag_distance < last_drag_distance else (1 - touch_zoom_speed)
				new_zoom *= zoom.x
				
				zoom = Vector2.ONE * new_zoom
				
				set_zoom(new_zoom)
				
				last_drag_distance = drag_distance

func _input(event):
	if Global.is_popup_visible(): return
	if !owner.edit_mode or owner.is_paused: return
	
	handle_touchscreen_input(event)
	
	# If we press the spacebar, enable camera drag mode.
	# This allows the camera to be moved by moving the mouse.
	if event.is_action("editor_move_camera"):
		mouse_drag_pressed = event.is_action_pressed("editor_move_camera", true)
		if mouse_drag_pressed and owner.mouse_over_ui: return
		if !mouse_drag_pressed:
			mouse_dragging_camera = false
			mouse_motion = Vector2.ZERO
	
	if event.is_action_pressed("editor_zoom_in") or event.is_action_pressed("editor_zoom_out"):
		var zoom_factor = 1 if event.is_action_pressed("editor_zoom_in") else -1
		
		var new_zoom = zoom - Vector2.ONE * mouse_zoom_speed * zoom_factor
		set_zoom(new_zoom)
		
		var mouse_pos = get_viewport().get_mouse_position()
		var mouse_pos_relative_to_center_of_screen = mouse_pos - ResolutionManager.window_resolution * Vector2(0.5,0.5)
		
		position += (mouse_pos_relative_to_center_of_screen * zoom_factor) * mouse_zoom_speed
	
	# If a mouse movement is detected and we are in camera drag mode,
	# move the camera by the mouse's relative movement * the specified mouse drag strength
	if event is InputEventMouseMotion:
		if mouse_drag_pressed:
			mouse_dragging_camera = true
			mouse_motion = event.relative * -1 * mouse_drag_strength

func camera_to_player_position(player : Node2D, worldmap = false):
	if !player:
		print("Error setting camera to player position: No player given")
		push_error("Error setting camera to player position: No player given")
		return
	
	set_global_position( player.get_global_position() )
	set_zoom(Vector2.ONE)
	
	tux_sprite.update_tux_sprite(player.state, worldmap)

func initialise_tux_sprite(level : Node2D):
	var worldmap = level.get("is_worldmap")
	
	# When loading into a worldmap, set Tux's position to the worldmap spawn point
	if position == Vector2.ZERO:
		var spawn_pos = level.get("spawn_position")
		if spawn_pos:
			position = spawn_pos * Global.TILE_SIZE + Global.TILE_SIZE * Vector2.ONE * 0.5
		else:
			position = Vector2.ONE * Global.TILE_SIZE * Vector2(5.5, 13.5)
	
	tux_sprite.initialise_tux_sprite(worldmap)

func _process(delta):
	if Global.is_popup_visible(): return
	visible = owner.edit_mode
	
	if owner.is_paused or !owner.edit_mode: return
	
	var move_dir = Vector2()
	move_dir.x = int(Input.is_action_pressed("move_right") or Input.is_action_pressed("editor_right")) - int(Input.is_action_pressed("move_left") or Input.is_action_pressed("editor_left"))
	move_dir.y = int(Input.is_action_pressed("duck") or Input.is_action_pressed("editor_down")) - int(Input.is_action_pressed("move_up") or Input.is_action_pressed("editor_up"))
	
	var velocity = move_dir * move_speed * delta * 60
	
	var edge_top = limit_top# + ResolutionManager.window_resolution.y * 0.5 * zoom.y
	var edge_left = limit_left# + ResolutionManager.window_resolution.x * 0.5 * zoom.x
	
	velocity += mouse_motion / self.cam_zoom
	
	position += velocity
	
	position.x = max(position.x, edge_left)
	position.y = clamp(position.y, edge_top, limit_bottom)

func _is_dragging_camera():
	return mouse_dragging_camera or touch_dragging_camera

func update_touch_events(new_value):
	touch_events = new_value
	touch_dragging_camera = touch_events.size() > 1

func _get_global_camera_zoom():
	return Vector2(get_global_transform_with_canvas().x.x, get_global_transform_with_canvas().y.y)
