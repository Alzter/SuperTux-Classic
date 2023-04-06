extends Node2D

onready var grumbel = $Grumbel
onready var anim_player = $AnimationPlayer
onready var statue = $Statue

func _ready():
	grumbel.connect("fake_death", self, "phase_two_transition")
	grumbel.connect("phase_two", self, "phase_two")
	
	if Scoreboard.number_of_deaths > 0:
		grumbel.enable()
		statue.hide()
	else:
		pass

func phase_two_transition():
	anim_player.play("phase_two_transition")

func phase_two():
	anim_player.play("phase_two")
