extends KinematicBody2D

export var invincible_time = 2.0
export var fireballs_per_hit = 3

export var max_health = 5
export var max_health_phase_two = 8

export var fireball_scene : PackedScene
export var powerup_small_scene : PackedScene
export var powerup_big_scene : PackedScene

onready var ai = $AI
onready var state_machine = $StateMachine
onready var anim_player = $AnimationPlayer
onready var fire_hit_anim = $FireHitAnim
onready var bounce_area = $BounceArea
onready var damage_area = $DamageArea
onready var sfx = $SFX
onready var invincible_timer = $InvincibleTimer
onready var aura = $Aura
onready var eye_positions = $EyePositions
onready var fireball_timer = $FireballTimer
onready var powerup_spawn_pos = $PowerupSpawn

onready var health = max_health
onready var tween = $Tween

var _initial_position = Vector2()
var velocity = Vector2()

var invincible = false
var fireball_hits = 0

var _angle = 0
var player = null
var anger = 0

var phase = 1

signal fake_death

func _ready():
	_initial_position = position

func set_anger():
	anger = abs(health - max_health) * (1.0 / (max_health - 1.0))
	if phase == 1: anger *= 0.8
	# Anger is 0 when grumbel is on max health, and 1 when grumbel is about to die
	# The lower health grumbel has, the angrier he is

func idle():
	fireball_timer.start()
	#disable_bounce_area(false)
	#disable_damage_area(false)

func idle_loop(delta):
	var move_speed = 3 + anger * 1.5
	var radius = Vector2(200, 200)
	var lerp_speed = 0.05
	
	_angle += delta * move_speed
	var offset = Vector2(sin(_angle * 0.6), cos(_angle * 0.5)) * radius
	
	var new_position = _initial_position + offset
	position.x = lerp(position.x, new_position.x, lerp_speed)
	position.y = lerp(position.y, new_position.y, lerp_speed)

func shoot_eye_fireballs(fireball_packed_scene = fireball_scene):
	Global.camera_shake(50, 0.7)
	sfx.play("Fireball")
	for eye in eye_positions.get_children():
		var eye_position = eye.global_position
		instance_node(fireball_packed_scene, eye_position)

func instance_node(packedscene, global_pos):
	var child = packedscene.instance()
	child.global_position = global_pos
	Global.current_scene.add_child(child)
	return child

func squished():
	disable_bounce_area()
	disable_damage_area()
	invincible = true
	fireball_hits = 0
	sfx.play("Squish")
	sfx.play("Squish2")
	Global.camera_shake(80, 0.92)
	fire_hit_anim.play("default")
	spawn_powerup()

func fake_death():
	disable_bounce_area()
	disable_damage_area()
	sfx.play("Squish")
	sfx.play("FakeDie")
	velocity = Vector2.ZERO
	emit_signal("fake_death")
	Music.pitch_slide_down()
	enable_phase_two()

func enable_phase_two():
	health = max_health_phase_two
	phase = 2

func fake_death_loop(delta):
	velocity.x = 0
	velocity.y += Global.gravity * delta
	position += velocity * delta

func update_sprite():
	modulate.a = 0.5 if invincible else 1
	aura.visible = !invincible

func be_bounced_upon(body):
	if body.is_in_group("players"):
		player = body
		body.bounce()
		health -= 1
		if health <= 0:
			if phase == 1:
				state_machine.set_state("fake_death")
		else:
			state_machine.set_state("squished")

func disable_bounce_area( disabled = true ):
	if bounce_area != null:
		for child in bounce_area.get_children():
			child.set_deferred("disabled", disabled)

func disable_damage_area( disabled = true ):
	#set_collision_layer_bit(2, !disabled)
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


func _on_FireballTimer_timeout():
	if state_machine.state == "idle":
		if !invincible: shoot_eye_fireballs()
		fireball_timer.start(3 - anger * 3)

func spawn_powerup():
	if player == null: return
	
	if player.state == player.states.FIRE: return
	
	var player_is_small = player.state == player.states.SMALL
	var powerup_to_spawn = powerup_small_scene if player_is_small else powerup_big_scene
	
	
	var powerup = instance_node(powerup_to_spawn, powerup_spawn_pos.global_position)
	powerup.velocity = Vector2(0, -300)
	powerup.intangibility_timer = 0.5


func _on_VisibilityNotifier2D_screen_exited():
	if state_machine.state == "fake_death":
		state_machine.set_state("phase_two_transition")

func phase_two_transition():
	yield(get_tree().create_timer(1), "timeout")
	
	anim_player.play("angry")
	var pos_y = _initial_position.y - Global.TILE_SIZE * 4
	tween.interpolate_property(self, "position:y", position.y, pos_y, 6, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()
