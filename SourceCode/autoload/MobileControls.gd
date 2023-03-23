extends CanvasLayer

var is_using_mobile = false

func _ready():
	is_using_mobile = OS.has_feature("mobile")
	if is_using_mobile: activate_mobile_controls()

func _input(event):
	if !is_using_mobile:
		if event is InputEventScreenTouch:
			is_using_mobile = true
			activate_mobile_controls()

func activate_mobile_controls():
	pass
