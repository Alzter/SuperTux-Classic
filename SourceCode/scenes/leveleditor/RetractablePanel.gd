extends Control

onready var anim_player = $RetractAnimation

var retracted = false

func _on_RetractTab_pressed():
	if retracted: anim_player.play("expand")
	else: anim_player.play("retract")
	retracted = !retracted
