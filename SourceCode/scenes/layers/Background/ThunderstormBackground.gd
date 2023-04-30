extends ParallaxBackground

onready var anim_player = $AnimationPlayer
onready var lightning_timer = $LightningTimer
onready var sound = $SFX/Lightning
onready var sfx = $SFX

func _on_LightningTimer_timeout():
	var rng = RandomNumberGenerator.new()
	var random_time = rng.randf_range(2,30)
	
	anim_player.play("lightning")
	lightning_timer.start(random_time)
	
	#sound.pitch_scale = rng.randf_range(1.9, 2.1)
	sfx.play("Lightning")
