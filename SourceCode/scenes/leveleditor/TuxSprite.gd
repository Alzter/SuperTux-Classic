extends Node2D

onready var sprite_small = $TuxSmall
onready var sprite_big = $TuxBig
onready var sprite_worldmap_small = $TuxWorldmapSmall
onready var sprite_worldmap_big = $TuxWorldmapBig
onready var tux_sprites = [sprite_big, sprite_small, sprite_worldmap_small, sprite_worldmap_big]

onready var sprite_colour = $SpriteColour

var tux_state = 0

func initialise_tux_sprite(is_in_worldmap : bool):
	update_tux_sprite(tux_state, is_in_worldmap)

func update_tux_sprite(powerup_state : int, is_in_worldmap : bool):
	
	for sprite in tux_sprites: sprite.hide()
	
	var small_sprite = sprite_worldmap_small if is_in_worldmap else sprite_small
	var big_sprite = sprite_worldmap_big if is_in_worldmap else sprite_big
	
	var sprite = big_sprite if powerup_state > 0 else small_sprite
	
	sprite.show()
	
	if powerup_state == 2:
		sprite_colour.play("red")
	else: sprite_colour.play("black")
	
	tux_state = powerup_state
