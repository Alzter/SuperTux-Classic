extends CanvasLayer

var is_using_mobile = false
export var force_mobile_controls = false

export var deadzone = 0.2
export var max_direction_distance = 1
# If the direction you're holding has a distance less than this to a cardinal direction
# you will be moving in the cardinal direction
# E.g. If my joystick direction is Vector2.UP and the angle between Vector2.UP and Vector2.LEFT
# is lower than 0.8 radians, I will be moving left

var joystick_active = false
var movement_vector = Vector2.ZERO

onready var mobile_controls = $Control
onready var joystick_button = $Control/Joystick/JoystickButton
onready var joystick_container = $Control/Joystick

var cardinal_directions = {
	Vector2.LEFT : "move_left",
	Vector2.RIGHT : "move_right",
	Vector2.UP : "move_up",
	Vector2.DOWN : "duck",
}

var movement_directions = []

func _ready():
	mobile_controls.hide()
	if OS.has_feature("mobile") or force_mobile_controls: activate_mobile_controls()

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if !is_using_mobile: activate_mobile_controls()
		if joystick_button.is_pressed():
			joystick_active = true
			movement_vector = get_movement_vector(event.position)
	
	if event is InputEventScreenTouch:
		if event.pressed == false:
			joystick_active = false

func _physics_process(delta):
	if !is_using_mobile: return
	
	mobile_controls.visible = Scoreboard.visible
	if !Scoreboard.visible: return
	
	if joystick_active and movement_vector.length() > deadzone:
		
		movement_directions = []
		
		for direction in cardinal_directions:
			var direction_distance = abs(movement_vector.normalized().angle_to(direction))
			if direction_distance < max_direction_distance:
				var direction_action = cardinal_directions.get(direction)
				movement_directions.append(direction_action)
		
		for direction in cardinal_directions:
			var direction_action = cardinal_directions.get(direction)
			if movement_directions.has(direction_action):
				Input.action_press(direction_action)
			else:
				Input.action_release(direction_action)
	
	else: clear_directions()

func clear_directions():
	if movement_directions != []:
		for direction in cardinal_directions:
			var direction_action = cardinal_directions.get(direction)
			if Input.is_action_pressed(direction_action):
				Input.action_release(direction_action)
		movement_directions = []

func get_movement_vector(touch_position):
	var joystick_center_position = joystick_button.global_position + joystick_container.rect_size * 0.5
	var position_difference = touch_position - joystick_center_position
	position_difference *= 2.0 / joystick_container.rect_size.x
	if position_difference.length() > 1: position_difference = position_difference.normalized()
	return position_difference

func activate_mobile_controls():
	is_using_mobile = true
	mobile_controls.show()

func _on_JumpButton_pressed():
	Input.action_press("jump")

func _on_JumpButton_released():
	Input.action_release("jump")
