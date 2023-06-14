extends Area2D

signal left_clicked
signal right_clicked
signal middle_clicked

onready var hitbox = get_node_or_null("CollisionShape2D")

onready var debug_rect_start = $CanvasLayer/Sprite
onready var debug_rect_end = $CanvasLayer/Sprite2

var mouse_over_hitbox = false # Is the mouse hovering over this click hitbox?
export var clickable = true # Can the hitbox be clicked?

onready var object = get_parent()

func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var screen_area = _get_hitbox_screen_area()
		if !screen_area: return
		
		var mouse_pos = event.position
		mouse_over_hitbox = screen_area.has_point(mouse_pos)
		#print(mouse_over_hitbox)
	
	if event is InputEventMouseButton and event.pressed:
		if clickable and mouse_over_hitbox:
			match event.button_index:
				BUTTON_LEFT: emit_signal("left_clicked")
				BUTTON_RIGHT: emit_signal("right_clicked")
				BUTTON_MIDDLE: emit_signal("middle_clicked")

# Returns a Rect2 which encloses the click hitbox's area on the screen.

# For example, if the hitbox is in the top-left corner of the screen and has extents (32,32)
# The area taken up by the hitbox on screen will be [(-16,-16), (16,16)]

func _get_hitbox_screen_area():
	if !hitbox: return null
	
	var t = get_global_transform_with_canvas()
	
	var screen_pos = t.origin
	var screen_zoom = Vector2(t.x.x, t.y.y)
	
	var hitbox_size = hitbox.shape.extents
	var screen_hitbox_size = hitbox_size * screen_zoom
	var hitbox_pos = screen_pos
	
	var screen_area = Rect2(screen_pos - (screen_hitbox_size), screen_hitbox_size * 2)
	
	#debug_rect_start.position = screen_area.position
	#debug_rect_end.position = screen_area.end
	
	return screen_area

func _on_ClickHitbox_left_clicked():
	Global.object_clicked(object, BUTTON_LEFT)

func _on_ClickHitbox_middle_clicked():
	Global.object_clicked(object, BUTTON_MIDDLE)

func _on_ClickHitbox_right_clicked():
	Global.object_clicked(object, BUTTON_RIGHT)
