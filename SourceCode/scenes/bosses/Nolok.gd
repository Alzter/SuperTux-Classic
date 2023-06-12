#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2022 Alexander Small <alexsmudgy20@gmail.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


extends KinematicBody2D

signal attack_finished

# BOUNDARIES
# Basically these act as invisible vertical walls at the edges of the level
# which Nolok cannot pass, to prevent him from falling off the level like a doofus
export var initial_health = 5
export var attack_cooldown = 0.75
export var facing = -1 setget set_facing
export var boundary_tile_left = 1
export var boundary_tile_right = 18
export var width = 128 # How wide is nolok? (chungus momen)
export (PackedScene) var iceblock_scene
export (PackedScene) var fireball_scene

export var fireballs_per_hit = 10 # If Nolok gets hit by X fireballs, it counts as a hit
var fireball_hits = 0 # How many fireball hits the player has racked up on Nolok

onready var bound_left = boundary_tile_left * Global.TILE_SIZE + width * 0.5
onready var bound_right = (boundary_tile_right + 1) * Global.TILE_SIZE - width * 0.5

onready var iceblock_throw_position = $Control/IceblockThrowPos
onready var fireball_position = $Control/FireballPosition
onready var control = $Control
onready var sfx = $SFX
onready var state_machine = $StateMachine
onready var attack_timer = $AttackCooldown # Nolok will do an attack once this timer depletes.
onready var ai = $AI
onready var tween = $Tween
onready var invulnerable_timer = $InvulnerableTimer
onready var health = initial_health

onready var anim_player = $AnimationPlayer
onready var sprite = $Control/AnimatedSprite

signal nolok_defeated

var speed = 1.4
var velocity = Vector2.ZERO
var gravity = Global.gravity
var invincible = false
var jump_distance_tiles = 8

func _ready():
	pass

func apply_friction():
	velocity.x *= 0.85

func apply_gravity(delta, gravity_set = gravity):
	velocity.y += gravity_set * delta

func apply_movement(delta, solid = true):
	if solid:
		velocity = move_and_slide(velocity, Vector2.UP)
	else:
		position += velocity * delta

# Starts a timer that, once depleted, makes Nolok execute a random attack.
func prepare_to_attack(time = attack_cooldown):
	attack_timer.start(time)

func _on_AttackCooldown_timeout():
	if ["startup", "idle"].has(state_machine.state):
		if Global.player != null and ai != null:
			ai.execute_random_attack()

# ==============================================================================
# Attacks
# ==============================================================================

# Does *amount* number of homing jumps, which each last for *duration* seconds.

func homing_jump(amount = 3, jump_duration = 0.8):
	jump_duration *= speed
	
	sfx.play("GruntJump")
	sprite.play("fireball")
	Global.camera_shake(20, 0.85)
	yield(wait(0.5, false), "completed")
	
	for i in amount - 1:
		if state_machine.state != "homing_jump": return
		yield(single_homing_jump(jump_duration), "completed")
		yield(wait(0.15, false), "completed")
	
	if state_machine.state != "homing_jump": return
	
	# Jump to the nearest corner of the level
	yield(single_homing_jump(jump_duration + 0.35, true), "completed")

func single_homing_jump(jump_duration, to_nearest_corner = false):
	if Global.player == null: return
	face_player()
	var jump_target_position = position.x + jump_distance_tiles * Global.TILE_SIZE * facing
	
	jump_target_position = clamp(jump_target_position, bound_left, bound_right)
	
	if to_nearest_corner:
		# If Nolok is closer to the left corner of the level, jump to there
		if abs(jump_target_position - bound_left) < abs(jump_target_position - bound_right):
			jump_target_position = bound_left
		else: jump_target_position = bound_right
	
	# Face the player
	face_player()
	
	sfx.play("Jump")
	sprite.play("jump")
	jump(8, jump_duration)
	
	tween.interpolate_property(self, "position:x",
	null, jump_target_position,
	jump_duration - 0.025, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween.start()
	
	yield(tween, "tween_completed")
	
	if state_machine.state != "homing_jump": return
	
	# Snap to the ground
	move_and_slide(Vector2(0, 64), Vector2.UP)
	Global.camera_shake(20, 0.8)
	sfx.play("Thump")
	sprite.play("idle")

# Makes Nolok jump X tiles high, and allows you to control how long he will stay in the air.
func jump(height_in_tiles: float, duration: float):
	var jump_height = height_in_tiles * Global.TILE_SIZE
	
	gravity = 2.0 * jump_height / pow(duration * 0.5, 2)
	
	jump_height = -sqrt(2 * gravity * jump_height)
	
	velocity.y = jump_height





func iceblock_kick():
	for i in 3:
		if state_machine.state != "iceblock_kick": return
		yield(throw_iceblock(), "completed")

func throw_iceblock():
	# Play "wind up" animation
	sfx.play("SpawnIceblock")
	sprite.play("iceblock")
	yield(wait(0.5), "completed")
	
	if state_machine.state != "iceblock_kick": return
	# Summon iceblock and play "throw" animation
	spawn_iceblock()
	sprite.play("idle")
	yield(wait(0.75), "completed")

func spawn_iceblock():
	var iceblock_position = iceblock_throw_position.global_position
	var iceblock = instance_node(iceblock_scene, iceblock_position)
	iceblock.call_deferred("get_kicked", self)





func fireball():
	sfx.play("GrowlCharge")
	for i in 3:
		if state_machine.state != "fireball": return
		yield(spawn_fireball(), "completed")

func spawn_fireball():
	sprite.play("firecharge")
	yield(wait(0.7, false), "completed")
	
	if state_machine.state != "fireball": return
	
	sfx.play("Fireball")
	sprite.play("fireball")
	sfx.play("GruntFireball")
	Global.camera_shake(10, 0.8)
	var fireball_pos = fireball_position.global_position
	var fireball = instance_node(fireball_scene, fireball_pos)
	
	yield(wait(0.3), "completed")
	
	if state_machine.state != "fireball": return
	
	sprite.play("idle")

func instance_node(packedscene, global_pos):
	var child = packedscene.instance()
	child.global_position = global_pos
	if "facing" in child: child.facing = facing
	return Global.add_child_to_level(child, self)





func set_invincible_timer(time):
	invincible = true
	invulnerable_timer.start(time)

# Detects if Iceblocks are colliding with Nolok
func _on_HurtBox_area_entered(area):
	if invincible: return
	var body = area.get_parent()
	if body.is_in_group("enemies"):
		if body.has_node("StateMachine"):
			if body.state_machine.state == "kicked":
				body.velocity = Vector2.ZERO
				body.queue_free()
				_get_hurt(body)

func face_player(body = Global.player):
	if body == null: return
	facing = sign(body.position.x - position.x)

func _get_hurt(body = null):
	health -= 1
	speed *= 0.9
	
	sfx.play("Hurt")
	
	if health <= 0:
		
		# Don't die if the player is already dying
		if Global.player != null:
			if Global.player.state_machine.state != "dead":
				_knock_out()
	
	else:
		Global.camera_shake(40, 0.8)
		sfx.play("GrowlHurt")
		anim_player.play("hurt")

# Preliminary stuff to prepare Nolok to be defeated
func _knock_out():
	emit_signal("nolok_defeated")
	invincible = true
	$DamageArea.queue_free()
	$CollisionShape2D.queue_free()
	
	Global.can_pause = false
	Scoreboard.hide()
	Music.stop_all()
	tween.stop_all()
	
	var player = Global.player
	player.can_die = false
	if player.grabbed_object != null: player.release_grabbed_object()
	
	clear_all_enemies()
	state_machine.set_state("knockout")

# Called once Nolok actually enters the knock out state
func knock_out():
	sfx.play("KnockOut")
	pause_mode = PAUSE_MODE_PROCESS
	sprite.play("knockout")
	face_player()
	update_sprite()
	velocity = Vector2.ZERO
	
	yield(Global.hitstop(2, 150, 0.95), "completed")
	Global.can_pause = false
	fall_off_screen()

func fall_off_screen():
	#z_index = 999
	face_player()
	sfx.play("GruntDefeated")
	sfx.play("GruntDefeated2")
	
	Engine.time_scale = 0.3
	velocity.x = -10 * Global.TILE_SIZE * facing
	jump(6, 0.8)
	state_machine.set_state("defeated")
	anim_player.play("knockout")

func clear_all_enemies():
	for node in Global.current_level.get_children():
		if node.is_in_group("enemies") or node.is_in_group("fireballs"):
			node.queue_free()

func _on_InvulnerableTimer_timeout():
	invincible = false

func set_facing(new_value):
	new_value = clamp(new_value, -1, 1)
	if new_value == 0: new_value = 1
	facing = new_value

func update_sprite():
	control.rect_scale.x = facing
	if state_machine.state == "idle":
		sprite.play("idle")

func wait(time, affected_by_speed = true):
	if affected_by_speed: time *= speed
	var wait_time = time
	yield(get_tree().create_timer(wait_time, false), "timeout")

# When Nolok touches a player fireball
func fireball_hit():
	if invincible: return
	
	fireball_hits += 1
	if fireball_hits >= fireballs_per_hit:
		fireball_hits = 0
		_get_hurt()
	else:
		sfx.play("FireHurt")
		anim_player.stop(true)
		anim_player.play("firehurt")
		Global.camera_shake(10, 0.7)
