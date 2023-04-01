extends KinematicBody2D

export var facing = -1
export var turn_on_walls = true
export var turn_on_cliffs = false
export var jump_height_in_tiles = 6.0
export var walk_speed = 0.8 * 4
export var run_speed = 8
export var max_health = 3
export var tux_position_offset = Vector2(0, -26)

var invincible = false
var velocity = Vector2()
var grounded = false
var touching_wall = false
var die_height = 2.0 * Global.TILE_SIZE

var player_entity = null

onready var walk_speed_tiles = walk_speed * 4 * Global.TILE_SIZE
onready var jump_height = jump_height_in_tiles * Global.TILE_SIZE
onready var health = max_health

onready var sprite = $Control/AnimatedSprite
onready var anim_player = $AnimationPlayer
onready var state_machine = $StateMachine
onready var hitbox = $DamageArea
onready var bounce_area = $BounceArea
onready var edge_turn = $EdgeTurn
onready var sfx = $SFX
onready var destroy_timer = $DestroyTimer
onready var player_riding_position = $RidingPosition
onready var invincible_timer = $InvincibleTimer

# Kinematic Equations
func _ready():
	var gravity = Global.base_gravity
	jump_height = -sqrt(2 * gravity * jump_height)
	die_height = -sqrt(2 * gravity * die_height)

func apply_movement(delta, solid = true):
	if solid:
		velocity = move_and_slide(velocity, Vector2(0, -1))
		
		grounded = is_on_floor()
		touching_wall = is_on_wall()
	else:
		position += velocity * delta

func apply_gravity(delta, grav_set = Global.gravity):
	velocity.y += grav_set * delta

func move_forward(turn_on_wall, turn_on_cliff, speed = walk_speed_tiles):
	if turn_on_wall and touching_wall: facing *= -1
	if turn_on_cliff and grounded and !edge_turn.is_colliding(): facing *= -1
	
	velocity.x = speed * facing

func be_bounced_upon(body):
	if body.is_in_group("players"):
		initiate_riding(body)

func initiate_riding(player):
	player_entity = player
	player_entity.global_position.y = global_position.y + tux_position_offset.y
	player_entity.facing = facing
	player.ride_entity(self)
	state_machine.set_state("being_ridden")
	disable_collision()
	collide_with_other_enemies(false)
	invincible = true
	hide()

func exit_riding(from_damage = false):
	invincible = false
	if from_damage: take_damage()
	
	show()
	
	position = player_entity.position - tux_position_offset
	facing = player_entity.facing
	player_entity = null
	
	if state_machine.state != "dead":
		temporary_invincibility()
		disable_collision(false)
		collide_with_other_enemies(true)
		state_machine.set_state("walk")

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
	
	sprite.flip_h = int(facing == -1)

# If true, this enemy will collide with other enemies.
# If false, this enemy will pass through other enemies.
func collide_with_other_enemies(colliding = true):
	set_collision_layer_bit(2, colliding)
	set_collision_mask_bit(2, colliding)

# When a player (or enemy) enters our hitbox
func _on_DamageArea_body_entered(body):
	if invincible: return
	if body == self: return
	if body.is_in_group("players"):
		if body.riding_entity: return
		if body.invincible and body.invincible_type == body.invincible_types.STAR:
			die(true)
		else: body.hurt(self)

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

func fireball_hit():
	take_damage()

func take_damage():
	if invincible: return
	health -= 1
	anim_player.play("firehurt")
	sfx.play("FireHurt")
	if health <= 0:
		die()

func _on_DestroyTimer_timeout():
	call_deferred("queue_free")

func temporary_invincibility():
	invincible = true
	invincible_timer.start()

func _on_InvincibleTimer_timeout():
	if state_machine.state == "dead": return
	invincible = false
