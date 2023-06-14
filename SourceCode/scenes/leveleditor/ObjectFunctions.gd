extends Node2D

var object_container = null

var dragged_object = null

var can_place_objects = true

var mouse_over_ui = false

onready var tile_selection = $SelectedTile
onready var tile_preview = $SelectedTile/TilePreview

func _ready():
	set_process(true)

func _process(delta):
	tile_selection.hide()
	
	if dragged_object:
		dragged_object.set_position(get_mouse_position(true))
	
	if object_container:
		
		if owner.can_place_tiles and !mouse_over_ui:
			var selected_tile_position = get_mouse_position(true)
			tile_selection.show()
			
			tile_preview.visible = !owner.eraser_enabled and !owner.eyedropper_enabled and !owner.current_object_resource == null
			tile_preview.flip_h = owner.flip_tiles_enabled
			
			tile_selection.set_position(selected_tile_position)

func _input(event):
	if !owner.can_place_tiles: return
	
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		mouse_over_ui = owner.mouse_over_ui or Global.is_popup_visible()
	
	if event is InputEventMouseButton:
		
		# Let go of dragged objects when mouse released
		if event.button_index == BUTTON_LEFT and !event.pressed:
			can_place_objects = true
			
			if dragged_object:
				if is_instance_valid(dragged_object):
					dragged_object.position = get_mouse_position(true)
					dragged_object = null
			return
		
		if event.pressed and event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
		
			if can_place_objects and !mouse_over_ui and !dragged_object and object_container:
				
				var is_erasing = event.button_index == BUTTON_RIGHT or owner.eraser_enabled
				
				if !is_erasing and event.button_index == BUTTON_LEFT:
					place_object()

func place_object():
	var level = owner.get("level")
	if !level: return
	if !is_instance_valid(level): return
	
	owner.add_undo_state()
	var position = get_mouse_position(true)
	var object_to_add = owner.current_object_resource
	
	if !object_to_add: return
	if !object_container: return
	
	var object = object_to_add.instance()
	object.position = position
	object_container.add_child(object)
	object.set_owner(level)
	
	owner.play_sound("PlaceObject")

func grab_object(object): # Begin allowing an object to be dragged by the mouse.
	 # Only allow dragging objects which can have their position modified
	if object.get("position"):
		dragged_object = object

func delete_object(object):
	
	if object.get_owner() == owner: return
	
	owner.play_sound("EraseObject")
	
	owner.add_undo_state()
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
