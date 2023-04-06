extends Area2D

onready var hitbox = $CollisionShape2D
onready var tween = $Tween

export var master_pull_strength = 1.0
export var pull_strength = Vector2(200, 300)
export var resist_pull_strength = Vector2(2, 100)

func _ready():
	appear()

func appear():
	tween.interpolate_property(hitbox.shape, "radius", 0, 300, 3, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()

func dissipate():
	tween.stop_all()
	tween.interpolate_property(hitbox.shape, "radius", 300, 0, 0.25, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()

func _process(delta):
	var size = hitbox.shape.radius * scale.x
	var shake = size * (1.0 / 40.0)
	Global.camera_shake(shake, 0.75)
	
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
			pull_speed *= master_pull_strength
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
