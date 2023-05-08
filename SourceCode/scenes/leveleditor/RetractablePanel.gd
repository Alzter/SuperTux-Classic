extends Control

onready var anim_player = $RetractAnimation
onready var add_layer_dialog = $AddLayerDialog

var retracted = false

func _on_RetractTab_pressed():
	if retracted: anim_player.play("expand")
	else: anim_player.play("retract")
	retracted = !retracted

func _on_AddLayerButton_pressed():
	if !owner.level: return
	add_layer_dialog.popup()
