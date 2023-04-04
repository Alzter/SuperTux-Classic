extends Node2D

onready var grumbel = $Grumbel
onready var anim_player = $AnimationPlayer

func _ready():
	grumbel.connect("fake_death", self, "phase_two_transition")
	grumbel.connect("phase_two", self, "phase_two")

func phase_two_transition():
	anim_player.play("phase_two_transition")

func phase_two():
	anim_player.play("phase_two")
