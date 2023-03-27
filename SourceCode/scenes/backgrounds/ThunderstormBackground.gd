extends ParallaxBackground

onready var anim_player = $AnimationPlayer

func _on_LightningTimer_timeout():
	anim_player.play("lightning")


func _on_AnimationPlayer_animation_finished(anim_name):
	pass # Replace with function body.
