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

export var initial_speed = 2
export var acceleration = 28
export var angle = 90

onready var speed = initial_speed * Global.TILE_SIZE
onready var destroy_timer = $DestroyTimer
onready var animation_player = $AnimationPlayer
onready var sfx = $SFX
onready var damage_area = $DamageArea/CollisionShape2D

var is_moving = true

func _ready():
	if Global.player != null:
		var player_pos = Global.player.position
		angle = get_angle_to(player_pos)

func _physics_process(delta):
	if !is_moving: return
	var velocity = Vector2(speed, 0).rotated(angle)
	speed += acceleration
	
	move_and_slide(velocity)
	if is_on_wall() or is_on_floor() or is_on_ceiling(): dissipate()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

func dissipate():
	damage_area.set_deferred("disabled", true)
	sfx.play("Dissipate")
	sfx.play("Dissipate2")
	destroy_timer.start()
	animation_player.play("dissipate")
	is_moving = false

func _on_DestroyTimer_timeout():
	call_deferred("queue_free")
