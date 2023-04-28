extends KinematicBody2D

export var enabled = true

export var phase = 1

export var attack_timer_phase_1 = [6,12]
export var attack_timer_phase_2 = [1,5]

export var invincible_time = 2.0
export var fireballs_per_hit = 3

export var max_health = 5
export var max_health_phase_two = 8

export var fireball_scene : PackedScene
export var black_hole_scene : PackedScene
export var shockwave_scene : PackedScene
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
onready var powerup_spawn_pos = $PowerupSpawn
onready var fireball_timer = $FireballTimer
onready var attack_timer = $AttackTimer
onready var chomp_hitbox = $ChompHitbox

onready var health = max_health
onready var tween = $Tween

onready var rng = RandomNumberGenerator.new()
onready var sprite = $Control

var _initial_position = Vector2()
var velocity = Vector2()

var invincible = false
var hurt = false
var fireball_hits = 0

var _angle = 0
var anger = 0

var player = null

signal fake_death
signal phase_two
signal defeated
signal dying
signal is_idle
signal hurt

func _ready():
	_initial_position = position
	enable(enabled)

func set_anger():
	var max_hp = max_health if phase == 1 else max_health_phase_two
	
	if max_hp == 1: anger = 1
	else: anger = abs(health - max_hp) * (1.0 / (max_hp - 1.0))
	
	if phase == 1: anger *= 0.8
	else: anger += 0.5
	
	anger = clamp(anger, 0, 1)
	# Anger is 0 when grumbel is on max health, and 1 when grumbel is about to die
	# The lower health grumbel has, the angrier he is

func idle():
	emit_signal("is_idle")
	start_fireball_timer()
	set_attack_timer()
	#disable_bounce_area(false)
	#disable_damage_area(false)

func set_attack_timer():
	var attack_time_min_max = attack_timer_phase_1 if phase == 1 else attack_timer_phase_2
	var attack_time = rng.randf_range(attack_time_min_max[0], attack_time_min_max[1])
	attack_time *= (1 - anger * 0.75)
	attack_timer.start(attack_time)

func idle_loop(delta):
	var move_speed = 3 + anger * 1.5
	var radius = Vector2(200, 200)
	var lerp_speed = 0.05
	
	_angle += delta * move_speed
	var offset = Vector2(sin(_angle * 0.6), cos(_angle * 0.5)) * radius
	
	var new_position = _initial_position + offset
	position.x = lerp(position.x, new_position.x, lerp_speed)
	position.y = lerp(position.y, new_position.y, lerp_speed)

func black_hole():
	invincible = true
	disable_bounce_area()
	disable_damage_area()
	
	anim_player.play("black_hole_charge")
	var charge_time = 0.25 - anger * 0.1
	yield(get_tree().create_timer(charge_time, false), "timeout")
	
	if state_machine.state != "black_hole": return
	
	anim_player.play("black_hole_attack")
	yield(get_tree().create_timer(0.25, false), "timeout")
	
	if state_machine.state != "black_hole": return
	
	var black_hole = instance_node(black_hole_scene, global_position)
	
	var black_hole_time = 3.0 - anger * 1.5
	var black_hole_size = 200.0 + anger * 200.0
	
	black_hole.appear(black_hole_time, black_hole_size)
	
	yield(get_tree().create_timer(black_hole_time - 0.5, false), "timeout")
	
	black_hole.dissipate()
	
	anim_player.play("black_hole_end")
	yield(get_tree().create_timer(0.25, false), "timeout")
	
	invincible = false
	disable_bounce_area(false)
	
	yield(anim_player, "animation_finished")
	
	disable_damage_area(false)
	idle_animation()
	
	yield(get_tree(), "idle_frame")

func chomp():
	invincible = true
	disable_bounce_area()
	disable_damage_area()
	
	anim_player.play("chomp_split")
	yield(get_tree().create_timer(0.25, false), "timeout")
	
	if state_machine.state != "chomp": return
	
	Global.camera_shake(30, 0.7)
	if phase == 1:
		yield(get_tree().create_timer(0.5, false), "timeout")
	else:
		yield(get_tree().create_timer(0.1, false), "timeout")
	#yield(anim_player, "animation_finished")
	
	if state_machine.state != "chomp": return
	
	var chomp_time = 1 - anger * 0.4 - int(phase == 2) * 0.25
	
	tween.interpolate_property(self, "position", position, player.position, chomp_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(get_tree().create_timer(chomp_time * 0.75, false), "timeout")
	
	if state_machine.state != "chomp": return
	
	anim_player.play("chomp_smash")
	yield(get_tree().create_timer(0.2, false), "timeout")
	
	if state_machine.state != "chomp": return
	
	Global.camera_shake(50, 0.7)
	chomp_kill_player()
	invincible = false
	disable_bounce_area(false)
	disable_damage_area(false)
	
	yield(anim_player, "animation_finished")
	
	if state_machine.state != "chomp": return
	
	idle_animation()
	yield(get_tree(), "idle_frame")

func chomp_kill_player():
	for body in chomp_hitbox.get_overlapping_bodies():
		if body.is_in_group("players"):
			if !body.invincible:
				body.global_position.x = global_position.x
				body.die()

func shoot_eye_fireballs(fireball_packed_scene = fireball_scene):
	Global.camera_shake(50, 0.7)
	sfx.play("Fireball")
	for eye in eye_positions.get_children():
		var eye_position = eye.global_position
		instance_node(fireball_packed_scene, eye_position)

func instance_node(packedscene, global_pos):
	var child = packedscene.instance()
	child.global_position = global_pos
	return Global.add_child_to_level(child, self)

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
	emit_signal("hurt")

func fake_death():
	invincible = true
	disable_bounce_area()
	disable_damage_area()
	sfx.play("Squish")
	sfx.play("FakeDie")
	velocity = Vector2.ZERO
	emit_signal("fake_death")

func defeated():
	anim_player.stop()
	anim_player.play("defeated")
	clear_all_enemies()
	
	emit_signal("defeated")
	
	invincible = true
	disable_bounce_area()
	disable_damage_area()
	
	pause_mode = PAUSE_MODE_PROCESS
	Scoreboard.hide()
	Global.can_pause = false
	Music.stop_all()
	
	var player = Global.player
	player.can_die = false
	
	sfx.play("Squish2")
	sfx.play("KnockOut")
	
	yield(Global.hitstop(2, 100, 0.99), "completed")
	die()

func die():
	emit_signal("dying")
	anim_player.play("dying")
	sfx.play("Dying")
	
	var shake = 10
	var rng = RandomNumberGenerator.new()
	
	while (anim_player.is_playing()):
		if shake == 30: instance_node(shockwave_scene, _initial_position)
		
		Global.camera_shake(shake, 0.9)
		shake += 1
		shake = min(shake, 100)
		position.x = lerp(position.x, _initial_position.x, 0.04)
		position.y = lerp(position.y, _initial_position.y, 0.04)
		
		var grumb_shake = shake * 0.05
		rng.randomize()
		position.x += rng.randf_range(-grumb_shake, grumb_shake)
		rng.randomize()
		position.y += rng.randf_range(-grumb_shake, grumb_shake)
		
		yield(get_tree(), "idle_frame")

func fake_death_loop(delta):
	velocity.x = 0
	velocity.y += Global.gravity * delta
	position += velocity * delta

func update_sprite():
	sprite.modulate.a = 0.5 if (invincible and hurt) else 1
	aura.visible = !(invincible and hurt)

func be_bounced_upon(body):
	if body.is_in_group("players"):
		player = body
		body.bounce()
		get_hit()

func get_hit():
	health -= 1
	if health <= 0:
		if phase == 1:
			state_machine.set_state("fake_death")
		else:
			state_machine.set_state("defeated")
	else:
		state_machine.set_state("squished")

func disable_bounce_area( disabled = true ):
	if bounce_area != null:
		if !is_instance_valid(bounce_area): return
		for child in bounce_area.get_children():
			child.set_deferred("disabled", disabled)

func disable_damage_area( disabled = true ):
	#set_collision_layer_bit(2, !disabled)
	if damage_area != null:
		if !is_instance_valid(damage_area): return
		for child in damage_area.get_children():
			child.set_deferred("disabled", disabled)

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"squished":
			if state_machine.state == "squished":
				state_machine.set_state("idle")
				hurt = true
		"angry":
			commence_phase_two()

func commence_phase_two():
	health = max_health_phase_two
	phase = 2
	fireball_hits = 0
	invincible = false
	hurt = false
	disable_bounce_area(false)
	disable_damage_area(false)
	state_machine.set_state("idle")
	emit_signal("phase_two")

func set_invincible(time = invincible_time):
	invincible = true
	invincible_timer.start(time)

func _on_InvincibleTimer_timeout():
	invincible = false
	hurt = false
	disable_bounce_area(false)
	disable_damage_area(false)


func fireball_hit():
	if invincible: return
	
	fireball_hits += 1
	if fireball_hits >= fireballs_per_hit:
		fireball_hits = 0
		get_hit()
	else:
		sfx.play("FireHurt")
		fire_hit_anim.stop()
		fire_hit_anim.play("firehit")
		Global.camera_shake(10, 0.7)


func _on_FireballTimer_timeout():
	if state_machine.state == "idle":
		if !invincible: shoot_eye_fireballs()
		start_fireball_timer()

func start_fireball_timer():
	fireball_timer.stop()
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
	yield(get_tree().create_timer(1, false), "timeout")
	
	anim_player.play("angry")
	var pos_y = _initial_position.y - Global.TILE_SIZE * 4
	tween.interpolate_property(self, "position:y", position.y, pos_y, 6, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()

func _on_AttackTimer_timeout():
	if state_machine.state == "idle":
		ai.execute_random_attack()
		set_attack_timer()

func idle_animation():
	if phase == 1: anim_player.play("idle")
	else: anim_player.play("phase_two")

func enable(enable = true, wait_time = 1):
	enabled = enable
	visible = enabled
	disable_bounce_area(!enabled)
	disable_damage_area(!enabled)
	invincible = !enabled
	if enabled:
		yield(get_tree().create_timer(wait_time, false), "timeout")
		if state_machine.state == "waiting":
			state_machine.set_state("idle")

func clear_all_enemies():
	for node in Global.current_level.get_children():
		if node.is_in_group("enemies") or node.is_in_group("fireballs"):
			node.queue_free()
