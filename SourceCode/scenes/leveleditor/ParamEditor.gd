extends Control

var parameter_to_change = null
var parameter_name = null
var parameter_type = null

func _ready():
	match parameter_type:
		TYPE_INT:
			pass
		TYPE_REAL: # Float data type
			pass
		TYPE_STRING:
			pass
		TYPE_BOOL:
			pass
		TYPE_COLOR:
			pass
