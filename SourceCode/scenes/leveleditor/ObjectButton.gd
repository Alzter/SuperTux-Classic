extends Button

#onready var control = $Control
onready var sprite = $Control/Sprite

var object_resource : Resource = null setget update_object_resource
signal object_button_pressed(object_resource)
signal update_tile_preview_texture(texture)

export var object_icons_dir = "res://images/editor/object_icons/"

func update_object_resource(new_value):
	object_resource = new_value
	
	if object_resource:
		if object_resource is Resource:
			
			var file_path = object_resource.resource_path
			var file_name = file_path.get_file().trim_suffix(".tscn")
			
			var icon_file = object_icons_dir + file_name + ".png"
			
			var icon_texture = load(icon_file)
			
			sprite.texture = icon_texture
	
	#var object = object_resource.instance()
	#control.add_child(object)
	#object.set_owner(control)
	#object.set_process(false)
	#object.set_physics_process(false)
	#object.set_process_input(false)
	#object.pause_mode = PAUSE_MODE_STOP

func _get_object_icon(path : String, texture : Texture, user_data):
	sprite.texture = texture

func _on_TileButton_pressed():
	emit_signal("object_button_pressed", object_resource)
	set_preview_texture()

func set_preview_texture():
	emit_signal("update_tile_preview_texture", sprite.texture, null)
