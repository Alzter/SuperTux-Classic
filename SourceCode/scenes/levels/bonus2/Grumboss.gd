extends Node2D

onready var grumbel = $Grumbel
onready var anim_player = $AnimationPlayer
onready var statue = $Statue

func _ready():
	grumbel.connect("fake_death", self, "phase_two_transition")
	grumbel.connect("phase_two", self, "phase_two")
	
	if Scoreboard.number_of_deaths > 0:
		grumbel.enable(true)
		statue.hide()
	else:
		statue_intro()

func statue_intro():
	Music.stop_all()
	yield(get_tree().create_timer(1), "timeout")
	

func phase_two_transition():
	anim_player.play("phase_two_transition")

func phase_two():
	anim_player.play("phase_two")
