extends Area2D

onready var anim_player = get_node_or_null("AnimationPlayer")

func _on_SecretArea_body_entered(body):
	if !anim_player: return
	if body.is_in_group("players"):
		anim_player.play("fade_out")

func _on_SecretArea_body_exited(body):
	if !anim_player: return
	if body.is_in_group("players"):
		anim_player.play("fade_in")
