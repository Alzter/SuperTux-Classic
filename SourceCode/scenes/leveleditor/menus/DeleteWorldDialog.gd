extends PopupDialog

onready var escape_button = $VBoxContainer/VBoxContainer/EscapeButton
onready var delete_button = $VBoxContainer/VBoxContainer/ConfirmDelete

onready var deletion_message = $DeletionMessage
onready var deletion_ok_button = $DeletionMessage/VBoxContainer/FinishDelete

onready var anim_player = get_node_or_null("AnimationPlayer")

export var is_level_delete = false

# If true, will force the user to wait before being able to press "Yes" to delete
export var delay_delete_button = true

var world_to_delete = ""
var level_to_delete = ""

signal delete_world
signal delete_level

func init_level(level_filepath : String):
	level_to_delete = level_filepath

func init_world(delete_world_folder_name : String):
	world_to_delete = delete_world_folder_name

func _on_DeleteWorldDialog_about_to_show():
	if anim_player:
		anim_player.stop()
		if delay_delete_button:
			anim_player.play("DeleteButtonAppear")
	
	escape_button.grab_focus()
	delete_button.disabled = delay_delete_button

func _on_AnimationPlayer_animation_finished(anim_name):
	delete_button.disabled = false

func _on_ConfirmDelete_pressed():
	if is_level_delete: emit_signal("delete_level", level_to_delete)
	else: emit_signal("delete_world", world_to_delete)
	deletion_message.popup()
	deletion_ok_button.grab_focus()

func _on_EscapeButton_pressed():
	hide()

func _on_FinishDelete_pressed():
	hide()
	deletion_message.hide()
