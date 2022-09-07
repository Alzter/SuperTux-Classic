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

onready var text = $CanvasLayer/Control/TextScroll

func _ready():
	Scoreboard.hide()
	yield(get_tree().create_timer(5.5, false), "timeout")
	$Stalactite.state_machine.set_state("shaking")
	yield(get_tree().create_timer(3, false), "timeout")
	Music.play("TuxVictorious")

func _on_AnimationPlayer_animation_finished(anim_name):
	text.start()
