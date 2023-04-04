extends KinematicBody2D

onready var ai = $AI
onready var state_machine = $StateMachine
onready var anim_player = $AnimationPlayer
onready var bounce_area = $BounceArea

func be_bounced_upon(body):
	if body.is_in_group("players"):
		body.bounce()
		state_machine.set_state("squished")

func disable_bounce_area( disabled = true ):
	if bounce_area != null:
		for child in bounce_area.get_children():
			child.set_deferred("disabled", disabled)
