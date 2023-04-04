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


extends StateMachine

func _ready():
	add_state("idle")
	add_state("squished")
	
	# Don't do anything until the level title card is gone
	yield(Global, "level_ready")
	
	call_deferred("set_state", "idle")

func _state_logic(delta):
	pass

func _enter_state(new_state, old_state):
	pass
	
	if new_state in host.ai.ATTACKS:
		# IF Grumbel is in an attacking state,
		
		# Execute the attack and wait until it finishes
		yield( host.call(new_state), "completed" )
		
		# Then if he's still in the same state, set his state to idle again
		if state == new_state:
			set_state("idle")
