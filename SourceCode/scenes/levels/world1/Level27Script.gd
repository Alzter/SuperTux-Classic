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


extends Node

onready var camera = get_parent().get_node("Camera2D")
onready var anim_player = get_parent().get_node("AnimationPlayer")
onready var nolok = get_parent().get_node("Nolok")

var boss_defeated = false
var lerp_speed = 0.02

func _ready():
	nolok.connect("nolok_defeated", self, "boss_defeated")

func boss_defeated():
	anim_player.play("defeated")
	boss_defeated = true

func _process(delta):
	
	# EXTREMELY hacky way to get the camera to pan towards Nolok once he is defeated
	if boss_defeated:
		lerp_speed *= 0.99
		camera.position.x = lerp(camera.position.x, nolok.global_position.x, lerp_speed)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "defeated":
		Global.level_completed()
