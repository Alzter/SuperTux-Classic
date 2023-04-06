extends Area2D

onready var hitbox = $CollisionShape2D
onready var size = hitbox.shape.radius

export var pull_strength = Vector2(100, 300)
export var resist_pull_strength = Vector2(1, 100)

func _process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("players"):
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

func set_size(new_size):
	hitbox.shape.set_deferred("radius", new_size)
	size = new_size
