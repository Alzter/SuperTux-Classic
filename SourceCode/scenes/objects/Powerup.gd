#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
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

export var type = ""
export var state_to_grant = 0 # Refer to player states enum for powerup states
export var facing = 1
export var can_move = true
export var bounces = false
export var move_speed_in_tiles = 0.8 * 4
export var bounce_height_in_tiles = 6.0
export var solid = true
export var friction = 0.75

var velocity = Vector2()
var touching_wall = false
var grounded = false
var moving = false
var is_solid = true
onready var move_speed = move_speed_in_tiles * Global.TILE_SIZE
onready var bounce_height = bounce_height_in_tiles * Global.TILE_SIZE

var intangibility_timer = 0

# Kinematic Equations
func _ready():
	var gravity = Global.base_gravity
	bounce_height = -sqrt(2 * gravity * bounce_height)

func _physics_process(delta):
	intangibility_timer -= delta
	if moving: move_forward()
	apply_gravity(delta)
	if bounces and moving: bounce()
	apply_movement(delta, is_solid)
	if !moving and grounded: velocity.x *= friction

func move_forward():
	if touching_wall: facing *= -1
	velocity.x = move_speed * facing

func apply_gravity(delta, grav_set = Global.gravity):
	velocity.y += grav_set * delta

func apply_movement(delta, solid):
	if solid:
		velocity = move_and_slide(velocity, Vector2(0, -1))
		
		grounded = is_on_floor()
		touching_wall = is_on_wall()
	else: position += velocity * delta

func bounce():
	if grounded:
		velocity.y = bounce_height
		grounded = false
		is_solid = solid

func _on_Area2D_body_entered(body):
	if intangibility_timer > 0: return
	
	if body.is_in_group("players"):
		match type:
			"Powerup":
				if body.state < state_to_grant:
					body.state = state_to_grant
			"Star":
				body.get_star()
			"1up":
				Scoreboard.lives += 1
		queue_free()

func _on_SpawnTimer_timeout():
	if can_move:
		moving = true

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
