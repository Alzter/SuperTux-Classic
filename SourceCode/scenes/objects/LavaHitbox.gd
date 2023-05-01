extends Area2D

onready var sprite = $Sprite

func _ready():
	sprite.hide()

func _on_Lava_body_entered(body):
	# If the body is invincible, don't kill it
#	if body.get("invincible"):
#		if body.invincible == true: return
	
	if body.has_method("die"):
		body.die()
