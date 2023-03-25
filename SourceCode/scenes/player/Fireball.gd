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

var velocity = Vector2()
var is_moving = true
var active = true

onready var animation_player = $AnimationPlayer
onready var destroy_timer = $DestroyTimer

func _ready():
	if velocity.x >= 0:
		animation_player.play("default")
	else:
		animation_player.play_backwards("default")

func _process(delta):
	if !is_moving: return
	apply_gravity(delta)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.normal.y == 0:
			dissipate()
			return
		velocity = velocity.bounce(collision.normal)
		position.x += velocity.x * delta
	if is_on_wall(): dissipate()

func apply_gravity(delta, gravity_set = Global.gravity):
	velocity.y += gravity_set * delta

func _on_EnemyKill_body_entered(body):
	if !is_moving: return
	if body.has_method("fireball_hit"):
		body.fireball_hit()
		dissipate()
		return
	
	if body.is_in_group("enemies"):
		if body.has_method("die"):
			if !body.invincible:
				body.die()
				dissipate()

func dissipate():
	if !active: return
	active = false
	free_fireball_slot()
	destroy_timer.start()
	animation_player.play("dissipate")
	is_moving = false

func _on_DestroyTimer_timeout():
	call_deferred("queue_free")

func _on_VisibilityNotifier2D_screen_exited():
	if !active: return
	active = false
	free_fireball_slot()
	call_deferred("queue_free")

func free_fireball_slot():
	Global.fireballs_on_screen -= 1
