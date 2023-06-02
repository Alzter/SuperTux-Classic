extends Button

onready var control = $Control

var object_resource : Resource = null setget update_object_resource
signal object_button_pressed(object_resource)

func update_object_resource(new_value):
	object_resource = new_value
	
	#var object = object_resource.instance()
	#control.add_child(object)
	#object.set_owner(control)
	#object.set_process(false)
	#object.set_physics_process(false)
	#object.set_process_input(false)
	#object.pause_mode = PAUSE_MODE_STOP

func _on_TileButton_pressed():
	emit_signal("object_button_pressed", object_resource)
