extends KinematicBody2D

export var invincible_time = 2.0
export var fireballs_per_hit = 5

onready var ai = $AI
onready var state_machine = $StateMachine
onready var anim_player = $AnimationPlayer
onready var fire_hit_anim = $FireHitAnim
onready var bounce_area = $BounceArea
onready var damage_area = $DamageArea
onready var sfx = $SFX
onready var invincible_timer = $InvincibleTimer
onready var aura = $Aura

export var max_health = 5

onready var health = max_health

var invincible = false
var fireball_hits = 0

func idle():
	pass
	#disable_bounce_area(false)
	#disable_damage_area(false)

func squished():
	fireball_hits = 0
	invincible = true
	sfx.play("Squish")
	sfx.play("Squish2")
	disable_bounce_area()
	disable_damage_area()
	Global.camera_shake(40, 0.95)
	fire_hit_anim.play("default")

func update_sprite():
	modulate.a = 0.5 if invincible else 1
	aura.visible = !invincible

func be_bounced_upon(body):
	if body.is_in_group("players"):
		body.bounce()
		state_machine.set_state("squished")

func disable_bounce_area( disabled = true ):
	if bounce_area != null:
		for child in bounce_area.get_children():
			child.set_deferred("disabled", disabled)

func disable_damage_area( disabled = true ):
	set_collision_layer_bit(2, !disabled)
	if damage_area != null:
		for child in damage_area.get_children():
			child.set_deferred("disabled", disabled)

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"squished":
			state_machine.set_state("idle")

func set_invincible(time = invincible_time):
	invincible = true
	invincible_timer.start(time)

func _on_InvincibleTimer_timeout():
	invincible = false
	disable_bounce_area(false)
	disable_damage_area(false)


func fireball_hit():
	if invincible: return
	
	fireball_hits += 1
	if fireball_hits >= fireballs_per_hit:
		fireball_hits = 0
		state_machine.set_state("squished")
	else:
		sfx.play("FireHurt")
		fire_hit_anim.stop()
		fire_hit_anim.play("firehit")
		Global.camera_shake(10, 0.7)
