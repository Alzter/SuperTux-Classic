extends Area2D

func _on_Lava_body_entered(body):
	if body.is_in_group("players"):
		if body.invincible: return
		body.die()
