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

export var title = ""
export var author = ""

onready var title_text = $Control/VBoxContainer/Title
onready var author_text = $Control/VBoxContainer/Author
onready var lives_counter = $Control/VBoxContainer/HBoxContainer/LivesCount

func _ready():
	Scoreboard.hide()
	title_text.bbcode_text = str("[center][wave]" + title)
	author_text.text = str("by " + author)
	lives_counter.text = str(Scoreboard.lives)

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		$Timer.stop()
		_dissapear()

func _on_Timer_timeout():
	_dissapear()

func _dissapear():
	queue_free()
	Scoreboard.show()
