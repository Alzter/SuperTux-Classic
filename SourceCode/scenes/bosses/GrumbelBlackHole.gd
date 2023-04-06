extends Area2D

onready var hitbox = $CollisionShape2D
onready var size = hitbox.shape.radius
#onready var kill_hitbox = $KillHitbox

export var pull_strength = Vector2(200, 300)
export var resist_pull_strength = Vector2(2, 100)

func _process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("players"):
			body.jump_terminable = false
			var distance = global_position - body.global_position
			var pull_factor = distance.length() / size
			pull_factor = max(1 - pull_factor, 0)
			var pull_direction = distance.normalized()
			
			# If Tux is running away from the black hole, reduce its pull speed
			var resisting_pull = sign(body.move_direction) == -sign(pull_direction.x)
			var pull_speed = resist_pull_strength if resisting_pull else pull_strength
			print(pull_speed)
			
			var pull_velocity = pull_direction * pull_factor * pull_speed
			
			#body.position += pull_velocity
			body.velocity += pull_velocity
			body.grounded = false
	
#	for body in kill_hitbox.get_overlapping_bodies():
#		if body.is_in_group("players"):
#			if !body.invincible:
#				body.die()

func set_size(new_size):
	hitbox.shape.set_deferred("radius", new_size)
	size = new_size
