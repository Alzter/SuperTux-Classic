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

onready var raycast = $RayCast2D
onready var hitbox = $Node2D/Area2D/CollisionShape2D

func _on_Area2D_body_entered(body):
	if body.is_in_group("players"):
		body.win()

func _ready():
	raycast.force_raycast_update()
	if raycast.is_colliding():
		# Make the hitbox shape unique since we're about to modify it
		hitbox.shape = hitbox.shape.duplicate(true)
		
		# Use the raycast to get the position of the roof above us
		var roof = raycast.get_collision_point() - raycast.global_position
		
		# Make the hitbox of the goal post not exceed this roof
		var hitbox_size = Vector2(16, round(abs(roof.y * 0.5) + 8))
		#print(hitbox_size)
		
		# Change the hitbox size to this new size (have to do it using this method or else)
		hitbox.shape.set_deferred("extents", hitbox_size)
		hitbox.position.y = 96 - abs(hitbox_size.y)
