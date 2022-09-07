#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2000 Bill Kendrick <bill@newbreedsoftware.com>
#  Copyright (C) 2004 Tobias Glaesser <tobi.web@gmx.de>
#  Copyright (C) 2004 Matthias Braun <matze@braunis.de>
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

export var type = ""
export var facing = -1
export var turn_on_walls = true
export var turn_on_cliffs = false
export var sprite_faces_direction = true
export var bounce_height_in_tiles = 6.0

var velocity = Vector2()
var move_speed = 0.8 * 4 * Global.TILE_SIZE
var bounce_move_speed = 1.3 * 4 * Global.TILE_SIZE
var kicked_speed = 3.5 * 5.5 * Global.TILE_SIZE
var flying_distance = 3 * Global.TILE_SIZE
var grounded = false
var touching_wall = false
var invincible = false
var die_height = 2.0 * Global.TILE_SIZE

onready var bounce_height = bounce_height_in_tiles * Global.TILE_SIZE
onready var sprite = $Control/AnimatedSprite
onready var state_machine = $StateMachine
onready var hitbox = $DamageArea
onready var bounce_area = $BounceArea if has_node("BounceArea") else null
onready var edge_turn = $EdgeTurn if has_node("EdgeTurn") else null
onready var block_raycast = $BlockRaycast if has_node("BlockRaycast") else null
onready var sfx = $SFX
onready var destroy_timer = $DestroyTimer

# Kinematic Equations
func _ready():
	if !sprite_faces_direction: facing = -1
	var gravity = Global.gravity
	bounce_height = -sqrt(2 * gravity * bounce_height)
	die_height = -sqrt(2 * gravity * die_height)

func apply_movement(delta, solid = true):
	if solid:
		velocity = move_and_slide(velocity, Vector2(0, -1))
		
		grounded = is_on_floor()
		touching_wall = is_on_wall()
	else:
		position += velocity * delta

func jumpy_movement():
	move_and_slide(velocity, Vector2(0, -1))
	grounded = is_on_floor()
	touching_wall = is_on_wall()

func flying_movement(delta):
	velocity = Vector2.ZERO
	if has_node("FlyingTarget"):
		var target = get_node("FlyingTarget")
		var distance = target.position.y - position.y
		velocity.y = distance / delta

func apply_gravity(delta, grav_set = Global.gravity):
	velocity.y += grav_set * delta

func move_forward(turn_on_wall, turn_on_cliff, speed = move_speed):
	if turn_on_wall and touching_wall: facing *= -1
	if turn_on_cliff and grounded and !edge_turn.is_colliding(): facing *= -1
	
	velocity.x = speed * facing

# Used by kicked Iceblocks to hit bricks when they crash into them
func hit_blocks(delta):
	var direction = Vector2(sign(velocity.x), 0)
	block_raycast.cast_to = Vector2.RIGHT * velocity * delta + direction
	block_raycast.position.x = 16 * sign(velocity.x)
	block_raycast.force_raycast_update()
	if block_raycast.is_colliding():
		var object = block_raycast.get_collider().get_parent()
		if object.is_in_group("blocks"):
			if object.has_method("be_hit_from_side"):
				object.call_deferred("be_hit_from_side", velocity, self)
				velocity.x = (block_raycast.get_collision_point() - block_raycast.global_position - direction).x / delta
				iceblock_ricochet()
				return

func jumpy_bounce():
	if grounded:
		velocity.y = bounce_height
		grounded = false
		sprite.frame = 0

func kicked_movement():
	if touching_wall:
		iceblock_ricochet()
	velocity.x = kicked_speed * facing

func iceblock_ricochet():
	facing *= -1
	sfx.play("Ricochet")

func be_bounced_upon(body):
	var state = state_machine.state
	if body.is_in_group("players"):
		body.bounce()
		
		if state == "squished" and type == "Iceblock":
			get_kicked(body)
		else:
			get_squished()

func get_squished():
	velocity = Vector2.ZERO
	collide_with_other_enemies(true)
	if type == "Iceblock":
		sfx.play("Stomp")
	else:
		sfx.play("Squish")
		disable_collision()
		invincible = true
	state_machine.set_state("squished")
	if type == "Bomb":
		$FuseTimer.start()

func get_kicked(body = null):
	# Face away from the player who kicked us
	if body != null:
		var direction = sign(position.x - body.position.x)
		if direction != 0: facing = direction
	
	collide_with_other_enemies(false)
	sfx.play("Kick")
	state_machine.set_state("kicked")

func get_grabbed():
	disable_collision()
	collide_with_other_enemies(false)
	state_machine.set_state("grabbed")

func grab_released():
	disable_collision(false)
	get_kicked()

func explode():
	invincible = true
	sfx.play("Explode")
	disable_collision(false)
	disable_bounce_area(true)
	collide_with_other_enemies(false)
	$Control/Explosion.visible = true
	destroy_timer.start()
	state_machine.set_state("explode")

func die(bounce = false):
	if invincible: return
	invincible = true
	sfx.play("Fall")
	velocity.y = die_height if bounce else 0
	z_index = 999
	disable_collision()
	collide_with_other_enemies(false)
	sprite.flip_v = true
	state_machine.set_state("dead")
	destroy_timer.start()

func disable_collision( disabled = true ):
	set_collision_layer_bit(2, !disabled)
	set_collision_mask_bit(2, !disabled)
	
	if hitbox != null:
		for child in hitbox.get_children():
			child.set_deferred("disabled", disabled)
	
	disable_bounce_area(disabled)

func disable_bounce_area( disabled = true ):
	if bounce_area != null:
		for child in bounce_area.get_children():
			child.set_deferred("disabled", disabled)

func update_sprite():
	var state = state_machine.state
	if sprite.frames.has_animation(state):
		sprite.play(state)
	
	if sprite_faces_direction:
		sprite.flip_h = int(facing == -1)

# If true, this enemy will collide with other enemies.
# If false, this enemy will pass through other enemies.
func collide_with_other_enemies(colliding = true):
	set_collision_layer_bit(2, colliding)
	set_collision_mask_bit(2, colliding)

# When a player (or enemy) enters our hitbox
func _on_DamageArea_body_entered(body):
	if body == self: return
	if body.is_in_group("players"):
		
		# If we're an iceblock which can be kicked, get kicked
		# (or get grabbed if player is holding run)
		if state_machine.state == "squished" and type == "Iceblock":
			if body.can_grab_enemy():
				body.call_deferred("grab_enemy", self)
			else:
				get_kicked(body)
			return
			
		# Otherwise just damage the player
		else:
			# EXCEPT for if the player has a star, in which case die
			if body.invincible and body.invincible_type == body.invincible_types.STAR:
				die(true)
			else: body.hurt(self)
	
	if body.is_in_group("enemies"):
		if ["kicked", "explode"].has(state_machine.state):
			body.die()

func _on_DestroyTimer_timeout():
	call_deferred("queue_free")

func _on_FuseTimer_timeout():
	explode()
