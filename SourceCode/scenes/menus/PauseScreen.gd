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


extends CanvasLayer

onready var menu = $Control
var paused = false setget _set_paused

func _ready():
	# Make the music mute if we pause the game.
	Music.pause_mode = PAUSE_MODE_INHERIT
	menu.hide()
	Global.can_pause = true

func _unhandled_input(event):
	if !Global.can_pause: return
	
	if event.is_action_pressed("ui_cancel"):
		self.paused = !paused

func _set_paused(new_value):
	paused = new_value
	get_tree().paused = paused
	Scoreboard.level_timer.paused = paused
	menu.visible = paused

func _on_Continue_pressed():
	self.paused = false

func _on_Restart_pressed():
	Global.respawn_player()

func _on_Quit_pressed():
	Global.goto_scene( Global.title_screen_scene )
