extends Control

onready var anim_player = $RetractAnimation
onready var add_layer_dialog = get_node_or_null("AddLayerDialog")

export var retracted = false

func _on_RetractTab_pressed():
	if retracted: anim_player.play("expand")
	else: anim_player.play("retract")
	retracted = !retracted

func _on_AddLayerButton_pressed():
	add_layer_dialog()

func add_layer_dialog():
	if !owner.level: return
	if !add_layer_dialog: return
	if owner.is_paused: return
	if !owner.edit_mode: return
	add_layer_dialog.is_in_worldmap = owner.level.is_worldmap
	add_layer_dialog.popup()

func _input(event):
	if Input.is_key_pressed(KEY_CONTROL):
		if Input.is_key_pressed(KEY_A):
			if !Global.is_popup_visible():
				add_layer_dialog()
