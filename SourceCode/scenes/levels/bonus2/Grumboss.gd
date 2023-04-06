extends Node2D

onready var grumbel = $Grumbel
onready var anim_player = $AnimationPlayer
onready var statue = $Statue
onready var sfx = $SFX

func _ready():
	grumbel.connect("fake_death", self, "phase_two_transition")
	grumbel.connect("phase_two", self, "phase_two")
	
	yield(Global, "level_ready")
	
	if Scoreboard.number_of_deaths > 0:
		grumbel.enable(true)
		statue.hide()
		Music.play("Prophecy")
	else:
		statue_intro()

func statue_intro():
	yield(get_tree().create_timer(1), "timeout")
	var timer = get_tree().create_timer(2)
	var shake = 0.05
	sfx.play("Rumbling")
	sfx.play("Rumbling2")
	while timer.time_left > 0:
		shake += 0.1
		statue.offset.x = sin(shake * shake) * shake
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	sfx.stop("Rumbling")
	sfx.stop("Rumbling2")

func phase_two_transition():
	anim_player.play("phase_two_transition")

func phase_two():
	anim_player.play("phase_two")
