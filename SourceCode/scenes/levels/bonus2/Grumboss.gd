extends Node2D

onready var grumbel = $Grumbel
onready var anim_player = $AnimationPlayer
onready var statue = $Statue
onready var sfx = $SFX
onready var ambience = $Ambience

func _ready():
	grumbel.connect("fake_death", self, "phase_two_transition")
	grumbel.connect("phase_two", self, "phase_two")
	grumbel.connect("defeated", self, "defeated")
	grumbel.connect("dying", self, "dying")
	
	yield(Global, "level_ready")
	
	if Scoreboard.number_of_deaths > 0 or grumbel.phase == 2 or grumbel.enabled:
		spawn_grumbel(0.1)
	else:
		statue_intro()

func spawn_grumbel(wait_time = 1):
	grumbel.enable(true, wait_time)
	statue.hide()
	yield(get_tree().create_timer(wait_time, false), "timeout")
	if grumbel.phase == 2:
		anim_player.play("phase_two")
	else: Music.play("Prophecy")

func statue_intro():
	yield(get_tree().create_timer(1, false), "timeout")
	var timer = get_tree().create_timer(2, false)
	var shake = 0.05
	sfx.play("Rumbling")
	sfx.play("Rumbling2")
	while timer.time_left > 0:
		Global.camera_shake(shake * 2, 0.5)
		shake += 0.1
		statue.offset.x = sin(shake * shake) * shake
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	
	statue.offset.x = 0
	anim_player.play("flash_in")
	
	while anim_player.is_playing():
		Global.camera_shake(shake * 2, 0.5)
		shake += 1
		statue.offset.x = sin(shake * shake) * shake
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	
	sfx.play("Explosion")
	sfx.play("Explosion2")
	sfx.play("Explosion3")
	
	sfx.stop("Rumbling")
	sfx.stop("Rumbling2")
	
	yield(get_tree().create_timer(2, false), "timeout")
	
	spawn_grumbel(2)
	anim_player.play("flash_out")
	yield(anim_player, "animation_finished")

func phase_two_transition():
	anim_player.play("phase_two_transition")

func phase_two():
	anim_player.play("phase_two")

func defeated():
	ambience.stop()
	pause_mode = Node.PAUSE_MODE_PROCESS
	anim_player.play("defeated")

func dying():
	anim_player.play("dying")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "dying":
		Global.level_completed()
