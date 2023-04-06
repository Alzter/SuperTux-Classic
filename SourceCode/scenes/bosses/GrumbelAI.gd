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

onready var host = get_parent()
onready var state_machine = host.get_node("StateMachine")

const ATTACKS = [
	"chomp",
	"chomp",
	"black_hole",
	
]

const UNLIKELY_ATTACKS = ["black_hole"]

var movelist = []
var current_attack = null

func _ready():
	_repopulate_move_list()

func _repopulate_move_list():
	movelist.append_array(ATTACKS)

func execute_random_attack():
	if movelist == []:
		_repopulate_move_list()
	
	randomize()
	current_attack = rand_range(0, movelist.size())
	current_attack = movelist[current_attack]
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	if current_attack in UNLIKELY_ATTACKS and rng.randi_range(1, 3) != 1:
		return
	
	# Then remove it from the array so we can't use it again
	# until we've run out of attacks
	var attack_id = movelist.find(current_attack)
	movelist.remove(attack_id)
	
	_begin_attack(current_attack)

func _begin_attack(attack):
	state_machine.set_state(attack)
