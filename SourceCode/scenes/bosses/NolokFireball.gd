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


extends Node2D

export var initial_speed = 1.5
export var acceleration = 28
export var angle = 90

onready var speed = initial_speed * Global.TILE_SIZE

func _ready():
	if Global.player != null:
		var player_pos = Global.player.position
		angle = get_angle_to(player_pos)

func _physics_process(delta):
	var velocity = Vector2(speed, 0).rotated(angle)
	speed += acceleration
	
	position += velocity * delta

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
