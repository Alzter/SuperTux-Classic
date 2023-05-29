extends Area2D

signal left_clicked
signal right_clicked
signal middle_clicked

func _on_ClickHitbox_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT: emit_signal("left_clicked")
			BUTTON_RIGHT: emit_signal("right_clicked")
			BUTTON_MIDDLE: emit_signal("middle_clicked")


func _on_ClickHitbox_right_clicked():
	Global.object_right_clicked(owner)
