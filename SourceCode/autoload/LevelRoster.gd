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

var levels = [
	"res://scenes/levels/world1/intro.tscn",
	"res://scenes/levels/world1/level1.tscn",
	"res://scenes/levels/world1/level2.tscn",
	"res://scenes/levels/world1/level3.tscn",
	"res://scenes/levels/world1/level4.tscn",
	"res://scenes/levels/world1/level5.tscn",
	"res://scenes/levels/world1/level6.tscn",
	"res://scenes/levels/world1/level7.tscn",
	"res://scenes/levels/world1/level8.tscn",
	"res://scenes/levels/world1/level9.tscn",
	"res://scenes/levels/world1/level10.tscn",
	"res://scenes/levels/world1/level11.tscn",
	"res://scenes/levels/world1/level12.tscn",
	"res://scenes/levels/world1/level13.tscn",
	"res://scenes/levels/world1/level14.tscn",
	"res://scenes/levels/world1/level15.tscn",
	"res://scenes/levels/world1/level16.tscn",
	"res://scenes/levels/world1/level17.tscn",
	"res://scenes/levels/world1/level18.tscn",
	"res://scenes/levels/world1/level19.tscn",
	"res://scenes/levels/world1/level20.tscn",
	"res://scenes/levels/world1/level21.tscn",
	"res://scenes/levels/world1/level22.tscn",
	"res://scenes/levels/world1/level23.tscn",
	"res://scenes/levels/world1/level24.tscn",
	"res://scenes/levels/world1/level25.tscn",
	"res://scenes/levels/world1/level26.tscn", # The Castle of Nolok
	
	"res://scenes/levels/world1/level27.tscn", # NOLOK BOSS FIGHT
	
	"res://scenes/levels/world1/extro.tscn" # The good ending :D
]

onready var first_level = levels[0]

func get_subsequent_level(current_level):
	var current_level_id = levels.find(current_level)
	
	if current_level_id == -1 or current_level_id == levels.size() - 1:
		return null
	
	var next_level_id = current_level_id + 1
	var next_level = levels[next_level_id]
	return next_level
