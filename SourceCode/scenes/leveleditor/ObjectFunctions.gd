extends Node2D

var object_container = null

var dragged_object = null

func _ready():
	set_process(true)

func _process(delta):
	if dragged_object:
		dragged_object.position = get_mouse_position(true)

func _input(event):
	if event is InputEventMouseButton:
		
		# Let go of dragged objects when mouse released
		if event.button_index == BUTTON_LEFT and !event.pressed:
			if dragged_object:
				if is_instance_valid(dragged_object):
					dragged_object.position = get_mouse_position(true)
					dragged_object = null

func grab_object(object): # Begin allowing an object to be dragged by the mouse.
	 # Only allow dragging objects which can have their position modified
	if object.get("position"):
		dragged_object = object

func delete_object(object):
	object.queue_free()
	
	if dragged_object:
		if is_instance_valid(dragged_object):
			if dragged_object == object: dragged_object = null

func get_mouse_position(align_to_grid = true):
	var mouse_pos = get_global_mouse_position()
	if align_to_grid:
		mouse_pos /= Global.TILE_SIZE
		mouse_pos = Vector2(floor(mouse_pos.x), floor(mouse_pos.y))
		mouse_pos *= Global.TILE_SIZE
		mouse_pos += Global.TILE_SIZE * Vector2.ONE * 0.5
	return mouse_pos
