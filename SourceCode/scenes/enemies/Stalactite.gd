#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2000 Bill Kendrick <bill@newbreedsoftware.com>
#  Copyright (C) 2004 Tobias Glaesser <tobi.web@gmx.de>
#  Copyright (C) 2004 Matthias Braun <matze@braunis.de>
#  Copyright (C) 2022 Alexander Small <alexsmudgy20@gmail.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


extends KinematicBody2D

var velocity = Vector2()
onready var ceiling_raycast = $CeilingRaycast
onready var player_raycast = $PlayerRaycast
onready var state_machine = $StateMachine
onready var fall_timer = $FallTimer
onready var sfx = $SFX
onready var sprite = $AnimatedSprite
onready var hitbox = $DamageArea
onready var animation_player = $AnimationPlayer
var grounded = false

func _ready():
	stick_to_ceiling()

func stick_to_ceiling(): # Finds the closest ceiling and aligns itself to it
	ceiling_raycast.force_raycast_update()
	if ceiling_raycast.is_colliding():
		var collision_y = ceiling_raycast.get_collision_point().y - ceiling_raycast.global_position.y
		collision_y += 24
		position.y += collision_y

func shake(): # Begin Shaking
	fall_timer.start()
	sfx.play("Crack")

func crash():
	disable_collision(true)
	sfx.play("Crash")

func disable_collision( disabled = true ):
	if hitbox != null:
		for child in hitbox.get_children():
			child.set_deferred("disabled", disabled)

func apply_gravity(delta, grav_set = Global.gravity):
	velocity.y += grav_set * delta

func apply_movement(delta):
	velocity = move_and_slide(velocity, Vector2(0, -1))
	grounded = is_on_floor()

func is_player_colliding():
	if player_raycast.is_colliding():
		var object = player_raycast.get_collider()
		if object != null:
			if object.is_in_group("players"):
				return true
	return false

func _on_FallTimer_timeout():
	state_machine.set_state("falling")

func update_sprite():
	var state = state_machine.state
	if animation_player.has_animation(state):
		animation_player.play(state)
	if sprite.frames.has_animation(state):
		sprite.play(state)

# When a player (or enemy) enters our hitbox
func _on_DamageArea_body_entered(body):
	if body.is_in_group("players"):
		body.hurt(self)
	if body.is_in_group("enemies"):
		if ["falling"].has(state_machine.state):
			if body.has_method("die"):
				body.die()
