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
	"res://scenes/levels/world1/Intro.tscn",
	"res://scenes/levels/world1/Level1.tscn",
	"res://scenes/levels/world1/Level2.tscn",
	"res://scenes/levels/world1/Level3.tscn",
	"res://scenes/levels/world1/Level4.tscn",
	"res://scenes/levels/world1/Level5.tscn",
	"res://scenes/levels/world1/Level6.tscn",
	"res://scenes/levels/world1/Level7.tscn",
	"res://scenes/levels/world1/Level8.tscn",
	"res://scenes/levels/world1/Level9.tscn",
	"res://scenes/levels/world1/Level10.tscn",
	"res://scenes/levels/world1/Level11.tscn",
	"res://scenes/levels/world1/Level12.tscn",
	"res://scenes/levels/world1/Level13.tscn",
	"res://scenes/levels/world1/Level14.tscn",
	"res://scenes/levels/world1/Level15.tscn",
	"res://scenes/levels/world1/Level16.tscn",
	"res://scenes/levels/world1/Level17.tscn",
	"res://scenes/levels/world1/Level18.tscn",
	"res://scenes/levels/world1/Level19.tscn",
	"res://scenes/levels/world1/Level20.tscn",
	"res://scenes/levels/world1/Level21.tscn",
	"res://scenes/levels/world1/Level22.tscn",
	"res://scenes/levels/world1/Level23.tscn",
	"res://scenes/levels/world1/Level24.tscn",
	"res://scenes/levels/world1/Level25.tscn",
	"res://scenes/levels/world1/Level26.tscn", # The Castle of Nolok
	
	"res://scenes/levels/world1/Level27BOSSBATTLE.tscn", # NOLOK BOSS FIGHT
	
	"res://scenes/levels/world1/Ending.tscn" # The good ending :D
]

onready var first_level = levels[0]

func get_subsequent_level(current_level):
	var current_level_id = levels.find(current_level)
	
	if current_level_id == -1 or current_level_id == levels.size() - 1:
		return null
	
	var next_level_id = current_level_id + 1
	var next_level = levels[next_level_id]
	return next_level
