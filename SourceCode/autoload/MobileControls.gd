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

var button_just_pressed = false
var button_just_released = false

onready var mobile_controls = $Control
onready var joystick_button = $Control/JoystickScale/JoystickArea/Joystick/JoystickButton
onready var joystick_container = $Control/JoystickScale/JoystickArea/Joystick
onready var joystick_stick = $Control/JoystickScale/JoystickArea/Joystick/Stick
onready var scale_joystick = $Control/JoystickScale
onready var scale_buttons = $Control/ButtonsScale

onready var buttons = [$Control/ButtonsScale/ButtonsArea/Jump/JumpButton, $Control/ButtonsScale/ButtonsArea/Action/ActionButton]

var mouse_over_ui = null setget , _get_mouse_over_ui

onready var mouse_hover_detectors = [
	get_node("Control/ButtonsScale/ButtonsArea"),
	get_node("Control/JoystickScale/JoystickArea"),
	get_node("Control/PauseArea")
]

var cardinal_directions = {
	Vector2.LEFT : "move_left",
	Vector2.RIGHT : "move_right",
	Vector2.UP : "move_up",
	Vector2.DOWN : "duck",
}

var movement_directions = []

func _ready():
	mobile_controls.hide()
	if force_mobile_controls: activate_mobile_controls()
	ResolutionManager.connect("window_resized", self, "window_resized")
	window_resized()

func window_resized():
	var scale = ResolutionManager.window_size.x
	
	var scale_power = 0.5
	
	scale /= 640 * ResolutionManager.screen_shrink
	scale *= scale_power
	scale += 1 - scale_power
	
	update_mobile_controls_scale(scale)

func update_mobile_controls_scale(ui_scale : float):
	scale_joystick.rect_scale = Vector2.ONE * ui_scale
	scale_buttons.rect_scale = Vector2.ONE * ui_scale

func _input(event):
	
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if !is_using_mobile: activate_mobile_controls()
	
	if !is_using_mobile: return
	
	# Disable mobile controls if a keyboard or controller input is detected.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		deactivate_mobile_controls()
	
	if button_just_released:
		button_just_released = false
		return
	if button_just_pressed:
		button_just_pressed = false
		return
	
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if joystick_button.is_pressed():
			joystick_active = true
			
			# Ignore joystick move inputs when the jump / run buttons
			# are being pressed.
			var any_button_pressed = false
			for button in buttons:
				if button.is_pressed():
					any_button_pressed = true
			
			var touch_on_left_side_of_screen = (event.position <= ResolutionManager.window_resolution * 0.5)
			#print(touch_on_left_side_of_screen)
			
			if !any_button_pressed or touch_on_left_side_of_screen:
				movement_vector = get_movement_vector(event.position)
	
	
	if event is InputEventScreenTouch:
		if event.pressed == false:
			joystick_active = false

func _physics_process(delta):
	if !is_using_mobile: return
	
	var edit_mode_enabled = !Scoreboard.score_visible and Global.is_in_editor and !Global.is_popup_visible()
	
	var enabled = (Scoreboard.score_visible or edit_mode_enabled) and !get_tree().paused
	
	# Hide run and action buttons when not in editor.
	scale_buttons.visible = !edit_mode_enabled
	
	mobile_controls.visible = enabled
	
	if !enabled: return
	
	if joystick_active and movement_vector.length() > deadzone:
#		var ignore_joystick_input = false
#		for button in buttons:
#			if button.is_pressed(): ignore_joystick_input = true
#		if ignore_joystick_input: return
		
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
	
	update_joystick_sprite()

func clear_directions():
	if movement_directions != []:
		for direction in cardinal_directions:
			var direction_action = cardinal_directions.get(direction)
			if Input.is_action_pressed(direction_action):
				Input.action_release(direction_action)
		movement_directions = []

func get_movement_vector(touch_position, limit = true):
	var joy_scale = scale_joystick.rect_scale.x
	
	var joystick_center_position = joystick_button.global_position + joystick_container.rect_size * 0.5
	
	joystick_center_position += Vector2.ONE * 64 * (joy_scale - 1)
	
	var position_difference = touch_position - joystick_center_position
	position_difference *= 2.0 / joystick_container.rect_size.x / joy_scale
	if position_difference.length() > 1 and limit: position_difference = position_difference.normalized()
	return position_difference

func update_joystick_sprite():
	joystick_stick.position = joystick_button.position + joystick_container.rect_size * 0.5
	joystick_stick.animation = "pressed" if joystick_active else "default"
	if joystick_active:
		joystick_stick.position += movement_vector * joystick_container.rect_size * 0.5

func activate_mobile_controls():
	is_using_mobile = true
	mobile_controls.show()

func deactivate_mobile_controls():
	is_using_mobile = false
	mobile_controls.hide()

func _on_JumpButton_pressed():
	Input.action_press("jump")
	button_just_pressed = true

func _on_JumpButton_released():
	#print("Jump Release")
	Input.action_release("jump")
	button_just_released = true

func _on_ActionButton_pressed():
	Input.action_press("run")
	button_just_pressed = true

func _on_ActionButton_released():
	Input.action_release("run")
	button_just_released = true

func _on_PauseButton_pressed():
	Input.action_release("ui_cancel")
	var a = InputEventAction.new()
	a.action = "ui_cancel"
	a.pressed = true
	Input.parse_input_event(a)

func _get_mouse_over_ui():
	if !is_using_mobile: return false
	if joystick_active: return true
	
	for area in mouse_hover_detectors:
		var hitbox = Rect2(Vector2.ZERO, area.rect_size)
		if hitbox.has_point(area.get_local_mouse_position()): return true
	
	return false
