extends StateMachine

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


func _ready():
	add_state("neutral")
	add_state("shaking")
	add_state("falling")
	add_state("crashed")
	
	call_deferred("set_state", "neutral")

func _state_logic(delta):
	match state:
		"falling":
			host.apply_gravity(delta)
			host.apply_movement(delta)
		"crashed":
			host.apply_gravity(delta)
			host.apply_movement(delta)

func _get_transition(delta):
	match state:
		"neutral":
			if host.is_player_colliding():
				return "shaking"
		"falling":
			if host.grounded:
				return "crashed"

func _enter_state(new_state, old_state):
	host.update_sprite()
	
	match new_state:
		"shaking":
			host.shake()
		"crashed":
			host.crash()

func _exit_state(old_state, new_state):
	pass
