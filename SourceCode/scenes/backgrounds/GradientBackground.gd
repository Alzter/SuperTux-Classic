extends ParallaxBackground

export var top_colour = Color(1,1,1)
export var bottom_colour = Color(0,0,0)

onready var top = $Background/ColorRect
onready var bottom = $Background/TextureRect

func _ready():
	top.modulate = top_colour
	bottom.modulate = bottom_colour
