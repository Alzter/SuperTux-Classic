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

export (PackedScene) var fireball_scene
export var jump_height_in_tiles = 5.0
export var run_jump_height_in_tiles = 6.0
export var riding_jump_height_in_tiles = 7.0
export var low_bounce_height_in_tiles = 2.0
export var high_bounce_height_in_tiles = 5.0

export var invincible_star_time = 10.0
export var invincible_warning_time = 3.0 # Tux flashes green this many seconds before the invincible star wears out
export var damage_safe_time = 1.0

var grounded = false setget _set_grounded_state
var jump_terminable = false
var velocity = Vector2()
var invincible = false

var move_direction = 0
var facing = 1
var grabbed_object = null
var fireball_speed = 16 * Global.TILE_SIZE
var fireball_amount = 2 # Amount of fireballs which can be shot at once

var walk_accel = 0.03 * pow(60, 2) / 8 # M1 SuperTux calculates acceleration by multiplying it by delta squared, so we cheat by multiplying the base movement acceleration values by that here
var run_accel = 0.04 * pow(60, 2) / 11

var walk_friction = 0.03 * pow(60, 2) / 8 # The speed at which the player slows down whilst walking
var run_friction = 0.03 * pow(60, 2) / 4 # The speed at which the player slows down whilst walking

var walk_min = 0.5 * Global.TILE_SIZE # Player speed gets set to this when beginning to move
var run_min = 1.0 * 4.5 * Global.TILE_SIZE # Player speed gets set to this when beginning to move with RUN held down

var walk_max = 2.3 * 4.5 * Global.TILE_SIZE # If X speed is over this, player is running
var run_max = 3.2 * 4.5 * Global.TILE_SIZE
var skid_min = 2.0 * 3 * Global.TILE_SIZE # Player can skid if travelling over this speed

var riding_accel = 0.025 * pow(60, 2) / 11
var riding_max = 4 * 4.5 * Global.TILE_SIZE # Max speed whilst riding Ice Dragon is increased

# These values all get re-calculated in the initialize function using kinematic equations (thanks Game Endeavor)
onready var jump_height = jump_height_in_tiles * Global.TILE_SIZE # WAS 5.2 The peak height of holding jump in blocks
onready var run_jump_height = run_jump_height_in_tiles * Global.TILE_SIZE # WAS 5.8 Same as above but while moving fast
onready var riding_jump_height = riding_jump_height_in_tiles * Global.TILE_SIZE

onready var bounce_height = low_bounce_height_in_tiles * Global.TILE_SIZE # Bounce height while not holding jump
onready var high_bounce_height = high_bounce_height_in_tiles * Global.TILE_SIZE # Bounce height while holding jump

var has_large_hitbox = false # Returns true if tux is using big Tux's hitbox
var can_die = true

enum states {SMALL, BIG, FIRE}
var state = states.SMALL setget update_state

enum invincible_types {DAMAGED, STAR}
var invincible_type = invincible_types.DAMAGED

onready var camera = $Camera2D
onready var state_machine = $StateMachine
onready var jump_buffer = $JumpBuffer
onready var coyote_timer = $CoyoteTimer
onready var bounce_raycasts = $BounceRaycasts
onready var duck_raycast = $DuckRaycast
onready var sprite_master = $Control
onready var sprites = [$Control/SpriteSmall, $Control/SpriteBig, $Control/Dragon]
onready var arm_sprite = $Control/GrabArm
onready var sfx = $SFX
onready var skid_timer = $SkidTimer
onready var invincible_timer = $InvincibleTimer
onready var invincible_warning_timer = $StarWarning
onready var win_timer = $WinTimer
onready var invincible_anim = $InvincibleAnimation
onready var grab_position = $GrabPosition

# These get swapped out depending on Tux's state
onready var small_nodes = [$HitboxSmall, $Control/SpriteSmall]
onready var big_nodes = [$HitboxBig, $Control/SpriteBig]
onready var dragon_sprite = $Control/Dragon
onready var hitbox_small = $HitboxSmall
onready var hitbox_big = $HitboxBig
onready var hitbox_riding = $HitboxRiding

var riding_entity = null

func _ready():
	Global.player = self
	initialize_character()
	update_state(Scoreboard.player_initial_state, false)

func initialize_character():
	var gravity = Global.base_gravity
	var delta = 60
	
	jump_height = -sqrt(2 * gravity * jump_height)
	run_jump_height = -sqrt(2 * gravity * run_jump_height)
	riding_jump_height = -sqrt(2 * gravity * riding_jump_height)
	
	bounce_height = -sqrt(2 * gravity * bounce_height)
	high_bounce_height = -sqrt(2 * gravity * high_bounce_height)
	
	if Global.spawn_position != null: position = Global.spawn_position

func apply_movement(delta, solid = true):
	if solid:
		velocity = move_and_slide(velocity, Vector2(0, -1))
	else:
		position += velocity * delta
	
	if camera.current:
		# Tux cannot go past the left side of the level
		position.x = max(position.x, 16)
	else:
		# If we're using a custom level camera (e.g. for Autoscrolling levels)
		# Constrain Tux's position to within the camera boundaries
		var level_camera = Global.get_current_camera()
		if level_camera != null:
			var horizontal_width = ResolutionManager.window_resolution.x * 0.5
			var zoom = level_camera.zoom.x
			var left_camera_boundary = level_camera.global_position.x - horizontal_width * zoom + 16
			var right_camera_boundary = level_camera.global_position.x + horizontal_width * zoom - 16
			
			# If Tux is outside the left or right camera boundary,
			# set boundary to the position of the boundary he is outside of
			var boundary = null
			if position.x < left_camera_boundary: boundary = left_camera_boundary
			elif position.x > right_camera_boundary: boundary = right_camera_boundary
			
			# If Tux is outside the camera boundaries,
			# try to push him back in using move_and_collide.
			# If he collides with a wall during this time, kill him
			if boundary:
				var kill_normal = Vector2.LEFT if boundary == left_camera_boundary else Vector2.RIGHT
				var distance = Vector2(boundary - global_position.x, 0)
				var collision = move_and_collide(distance)
				if collision:
					# Crush Tux if he is stuck and cannot be pushed into the camera boundaries
					if collision.get_normal() == kill_normal:
						die()
			
			#position.x = clamp(position.x, left_camera_boundary, right_camera_boundary)
			
			#print(str(position.x), ", ",  str(left_camera_boundary), ", ",  str(right_camera_boundary))
	
	self.grounded = is_on_floor()
	if grounded: jump_terminable = true

func apply_gravity(delta, gravity_set = Global.gravity):
	velocity.y += gravity_set * delta

func move_input():
	var input = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	return input

func horizontal_movement():
	var running = Input.is_action_pressed("run") or Global.auto_run
	
#	if sign(velocity.x) == move_direction and running or abs(velocity.x) >= walk_max:
#		running = true
	
	var speed = run_accel if running else walk_accel
	if riding_entity: speed = riding_accel
	
	var speedcap = run_max if running else walk_max
	if riding_entity: speedcap = riding_max
	
	var min_speed = run_min if running else walk_min
	
	var friction = run_friction if running else walk_friction
	
	# Set movement speed to min walk speed when initiating movement
	if move_direction != 0 and abs(velocity.x) < min_speed:
		velocity.x = min_speed * move_direction
	
	velocity.x += speed * move_direction
	if abs(velocity.x) > speedcap:
		velocity.x = speedcap * sign(velocity.x)
	
	# Skidding
	if grounded and sign(move_direction) == -sign(velocity.x):
		if abs(velocity.x) > min_speed:
			if skid_timer.time_left == 0:
				if abs(velocity.x) > skid_min:
					sfx.play("Skid")
					skid_timer.start()
					velocity.x *= 0.75
				else:
					velocity.x += velocity.x / 60
	
	# Slow down if not holding movement keys
	if move_direction == 0:
		if abs(velocity.x) < min_speed:
			velocity.x = 0
		else:
			# This is by far the wackiest way to slow down I've seen
			velocity.x += friction * -sign(velocity.x)

func _set_grounded_state(new_value):
	if grounded == new_value: return
	
	grounded = new_value
	if !grounded and velocity.y >= 0:
		coyote_timer.start()
	else:
		coyote_timer.stop()

func jump_input(running = abs(velocity.x) > walk_max):
	if Input.is_action_just_pressed("jump"):
		jump_buffer.start()
	
	var exit_riding = riding_entity and Input.is_action_pressed("move_up")
	var jump_velocity = run_jump_height if running else jump_height
	if riding_entity: jump_height = riding_jump_height
	
	var can_jump = grounded or coyote_timer.time_left > 0 or exit_riding
	
	if can_jump and jump_buffer.time_left > 0:
		jump_buffer.stop()
		velocity.y = jump_velocity
		sfx.play("Jump")
		self.grounded = false
		if exit_riding:
			jump_terminable = false
			stop_riding_entity()
	
	# Jump termination by letting go of jump key
	if velocity.y < 0 and !Input.is_action_pressed("jump") and jump_terminable:
		velocity.y = 0

# When the player is jumping, checks if any blocks above the player's head can be hit.
# When the player is falling, checks if any enemies below the player can be bounced on.
func check_bounce(delta):
	if !grounded:
		# Make Tux's bounce raycasts go beneath his hitbox if he's falling down,
		# And above his hitbox if he's falling up.
		bounce_raycasts.position.y = 18 * sign(velocity.y)
		
		# If Tux is big we need to move the bounce raycasts up a bit more when
		# he's jumping since his hitbox is taller
		if has_large_hitbox and velocity.y <= 0: bounce_raycasts.position.y -= 32
		
		# If Tux is riding a Dragon, lower the bounce raycasts when he's falling so they
		# are at the dragon's feet
		if riding_entity and velocity.y > 0: bounce_raycasts.position.y += 43
		
		var new_velocity
		
		# Make all the raycasts extend out to cover Tux's future position
		for raycast in bounce_raycasts.get_children():
			var direction = Vector2.DOWN if velocity.y > 0 else Vector2.UP
			raycast.cast_to = direction * Vector2.DOWN * delta + direction
			raycast.force_raycast_update()
			if raycast.is_colliding():
				
				var object = raycast.get_collider().get_parent()
				
				# Enemies can only be squashed if Tux is travelling downwards
				if velocity.y > 0 and object.has_method("be_bounced_upon"):
					velocity.y = (raycast.get_collision_point() - raycast.global_position - direction).y / delta
					object.call_deferred("be_bounced_upon", self)
					break
				
				# Bonus blocks can only be hit if Tux is travelling upwards
				elif velocity.y < 0 and object.has_method("be_hit_from_above"):
					object.call_deferred("be_hit_from_above", self)
					
					var velocity_adjust = (raycast.get_collision_point() - raycast.global_position - direction).y / delta
					if !new_velocity: new_velocity = velocity_adjust
					else: new_velocity = max(velocity_adjust, new_velocity)
		
		if new_velocity: velocity.y = new_velocity

func bounce(bounce_velocity = bounce_height):
	if state_machine.state != "duck": state_machine.set_state("jump")
	coyote_timer.stop()
	if Input.is_action_pressed("jump"):
		velocity.y = high_bounce_height
		jump_terminable = true
	else:
		velocity.y = bounce_height
		jump_terminable = false

func update_sprite():
	var anim = state_machine.state
	if skid_timer.time_left > 0 and grounded: anim = "skid"
	
	if riding_entity == null: play_animation(anim)
	else: play_animation("riding")
	if dragon_sprite.frames.has_animation(anim):
		dragon_sprite.play(anim)
	
	# Make Tux face the direction you're holding
	for sprite in sprites:
		sprite.flip_h = int(facing == -1)
	
	# Change Tux's colour depending on his state
	# Black: Normal, Red: Fire Tux, Green: Invincible Star is about to deplete
	var invincible_warning = false
	if invincible and invincible_type == invincible_types.STAR:
		if invincible_timer.time_left > 0 and invincible_warning_timer.time_left == 0:
			invincible_warning = true
	if invincible_warning:
		$SpriteColour.play("starwarning")
	elif state == states.FIRE:
		$SpriteColour.play("red")
	else: $SpriteColour.play("black")
	
	# Make Tux flash for his I-frames
	var tux_flashing = invincible and invincible_type == invincible_types.DAMAGED
	invincible_anim.play("invincible") if tux_flashing else invincible_anim.play("default")
	
	# Grabbing objects gives Tux an arm on top of his sprite
	if grabbed_object != null:
		arm_sprite.visible = !["jump", "fall", "skid", "duck"].has(anim)
		arm_sprite.animation = "small" if state == states.SMALL else "big"
		arm_sprite.flip_h = int(facing == -1)
	else: arm_sprite.visible = false

func play_animation(animation):
	for sprite in sprites:
		if sprite.frames.has_animation(animation):
			sprite.play(animation)

# CHANGING TUX'S POWER-UP LEVEL / STATE when he gets hit or obtains a powerup
func update_state(new_value, play_sound = true):
	new_value = clamp(new_value, 0, 2)
	var prev_state = state
	state = new_value
	
	has_large_hitbox = state != states.SMALL
	
	# Big to small
	if state == states.SMALL:
		toggle_nodes(big_nodes, false) # Turn off big tux's sprite/hitbox
		toggle_nodes(small_nodes, true) # Turn on small tux's sprite/hitbox
	
	# Small to big
	elif state != states.SMALL:
		toggle_nodes(small_nodes, false) # Turn off small tux's sprite/hitbox
		toggle_nodes(big_nodes, true) # Turn on big tux's sprite/hitbox
	
	var ducking = state_machine.state == "duck" or riding_entity
	duck_hitbox(ducking, !riding_entity) # We need to give Tux back the small hitbox if he's ducking
	# Otherwise if you get a fire flower while ducking you incorrectly are assigned
	# Tux's standing hitbox, which can result in clipping into terrain
	
	if !play_sound: return
	
	# Powering up
	if state > prev_state:
		if state == states.BIG:
			sfx.play("Big")
		else:
			sfx.play("Fire")
	
	# Getting hurt / powering down
	elif state < prev_state:
		sfx.play("Hurt")

# Called by enemies to damage the player
func hurt(hurting_body):
	if invincible: return
	
	# HUMAN SHIELD: If player is holding an ice cube and touches an enemy,
	# kill the ice cube as well as the enemy
	if grabbed_object != null and hurting_body.has_method("die"):
		var enemies_to_kill = [hurting_body, grabbed_object]
		for enemy in enemies_to_kill:
			enemy.die()
		grabbed_object = null
		
	else:
		if riding_entity:
			stop_riding_entity(true)
			return
		if state == states.SMALL:
			die()
		else: # Get hurt
			self.state -= 1
			set_invincible()

func die():
	if !can_die: return
	
	Scoreboard.number_of_deaths += 1
	Scoreboard.lives -= 1
	Scoreboard.player_initial_state = states.SMALL
	Scoreboard.stop_level_timer()
	
	sfx.play("Hurt")
	self.invincible = false
	self.state = states.SMALL
	if grabbed_object != null: release_grabbed_object()
	velocity = Vector2.ZERO
	velocity.y = run_jump_height
	# Disable all Tux's collision so nothing interferes with his death state
	toggle_nodes(small_nodes, false, true)
	toggle_nodes(big_nodes, false, true)
	z_index = 999 # Go to the front of the screen
	state_machine.set_state("dead")
	Global.can_pause = false

func set_invincible():
	if state_machine.state == "dead": return
	invincible_type = invincible_types.DAMAGED
	invincible_timer.start(damage_safe_time)
	invincible = true

func _on_InvincibleTimer_timeout():
	invincible = false

func toggle_nodes(nodes, enabled = true, only_hitbox = false):
	for node in nodes:
		if !only_hitbox: node.visible = enabled
		if node.get_class() == "CollisionShape2D":
			node.set_deferred("disabled", !enabled)

func can_duck():
	if riding_entity: return false
	var sm_state = state_machine.state
	if state != states.SMALL:
		if Input.is_action_pressed("duck"):
			return true
	return false

func can_unduck():
	return !duck_raycast.is_colliding()

func duck_hitbox(ducking = true, count_as_small_hitbox = true):
	if state == states.SMALL: return
	if count_as_small_hitbox: has_large_hitbox = !ducking
	hitbox_small.set_deferred("disabled", !ducking)
	hitbox_big.set_deferred("disabled", ducking)

func can_grab_enemy():
	if riding_entity: return false
	if ["idle", "walk", "jump", "fall", "duck"].has(state_machine.state):
		if grabbed_object == null and Input.is_action_pressed("run"):
			return true
	return false

func grab_enemy(body):
	grabbed_object = body
	if grabbed_object.has_method("get_grabbed"):
		grabbed_object.get_grabbed()

func update_grab_position():
	if !has_large_hitbox:
		grab_position.position.y = 0
	else: grab_position.position.y = -12
	grab_position.position.x = 24 * facing

func hold_object(body = grabbed_object):
	if body == null: return
	
	body.global_position = grab_position.global_position
	
	# Make held object face player
	if "facing" in body:
		body.facing = facing
	
	if !Input.is_action_pressed("run"):
		release_grabbed_object(body)

func release_grabbed_object(body = grabbed_object):
	if body.has_method("grab_released"):
		body.position.x += 24 * facing # Move the object away from you so it doesn't damage you
		body.grab_released()
	grabbed_object = null

func fireball_input():
	if Input.is_action_just_pressed("run"):
		if Global.fireballs_on_screen < fireball_amount:
			if state == states.FIRE and !riding_entity:
				Global.fireballs_on_screen += 1
				shoot_fireball()
			elif riding_entity:
				Global.fireballs_on_screen += 1
				shoot_fireball()

func shoot_fireball(bullet_to_instance = fireball_scene):
	var b = bullet_to_instance.instance()
	b.velocity.x = fireball_speed * facing
	b.velocity.x += velocity.x * 0.5
	Global.add_child_to_level(b, self)
	b.global_position = grab_position.global_position
	sfx.play("Shoot")

func get_star():
	invincible_type = invincible_types.STAR
	invincible = true
	var warning_time = invincible_star_time - invincible_warning_time
	invincible_warning_timer.start(warning_time)
	invincible_timer.start(invincible_star_time)
	sfx.play("Invincible")
	Music.play("Invincible")

func _on_VisibilityNotifier2D_screen_exited():
	if get_tree().paused or state_machine.state == "win":
		return
	
	if state_machine.state != "dead":
		die()
	else:
		if Scoreboard.lives == -1 and !Global.is_in_editor:
			Scoreboard.game_over()
		else:
			Global.respawn_player()

func win():
	# Save Tux's state so it loads in on the next level
	Scoreboard.player_initial_state = state
	
	# Give Tux invincibility
	invincible_timer.stop()
	invincible_type = invincible_types.STAR
	invincible = true
	can_die = false
	
	# Make Tux face to the right (or else he'd moonwalk)
	velocity.y *= 0.5
	facing = 1
	
	# Release any grabbed objects
	if grabbed_object != null: release_grabbed_object()
	
	state_machine.set_state("win")
	Music.play("LevelDone")
	Scoreboard.stop_level_timer()
	Scoreboard.hide()
	Global.can_pause = false
	
	# Once this timer depletes, load in the next level
	win_timer.start()
	
	#camera.smooth_zoom(0.5, 1)

func win_loop(jump_over_walls = true):
	if jump_over_walls and grounded and is_on_wall():
		self.grounded = false
		velocity.y = jump_height * 0.5
		sfx.play("Jump")
	
	velocity.x = run_min
	var anim = "walk" if grounded else "jump"
	play_animation(anim)

func _on_WinTimer_timeout():
	_progress_to_next_level()

func _progress_to_next_level():
	Global.level_completed()

# Press escape to skip victory sequence
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed: skip_end_sequence()
	if event.is_action_pressed("ui_cancel"):
		skip_end_sequence()

func skip_end_sequence():
	if win_timer.time_left > 0:
		Input.action_release("ui_cancel") # Jank it up! A D V A N C E D
		win_timer.stop()
		_progress_to_next_level()

func ride_entity(entity : Node2D):
	riding_entity = entity
	duck_hitbox(true, false)
	hitbox_riding.set_deferred("disabled", false)
	dragon_sprite.show()
	velocity.x *= 0.5

func stop_riding_entity(from_damage = false):
	if !riding_entity: return
	if from_damage:
		sfx.play("Hurt")
	dragon_sprite.hide()
	hitbox_riding.set_deferred("disabled", true)
	riding_entity.exit_riding(from_damage)
	riding_entity = null
	duck_hitbox(false)
	#set_invincible()
