extends KinematicBody2D

onready var ai = $AI
onready var state_machine = $StateMachine
onready var anim_player = $AnimationPlayer
onready var bounce_area = $BounceArea
onready var damage_area = $DamageArea

export var max_health = 5

onready var health = max_health

func be_bounced_upon(body):
	if body.is_in_group("players"):
		body.bounce()
		state_machine.set_state("squished")

func idle():
	disable_bounce_area(false)
	disable_damage_area(false)

func squished():
	disable_bounce_area()
	disable_damage_area()
	Global.camera_shake(40, 0.95)

func disable_bounce_area( disabled = true ):
	if bounce_area != null:
		for child in bounce_area.get_children():
			child.set_deferred("disabled", disabled)

func disable_damage_area( disabled = true ):
	if damage_area != null:
		for child in damage_area.get_children():
			child.set_deferred("disabled", disabled)

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"squished":
			state_machine.set_state("idle")
