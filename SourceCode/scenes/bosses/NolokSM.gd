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
	add_state("startup")
	
	# Attack loop
	add_state("idle")
	
	add_state("knockout")
	add_state("defeated")
	
	# Attacks
	add_state("homing_jump")
	add_state("fireball")
	add_state("iceblock_kick")
	
	# Don't do anything until the level title card is gone
	yield(Global, "level_ready")
	
	call_deferred("set_state", "idle")

func _state_logic(delta):
	if ["knockout", "defeated"].has(state):
		if state == "defeated":
			host.apply_gravity(delta)
			host.apply_movement(delta, false)
		return
	
	if ["startup", "idle"].has(state):
		host.face_player()
	host.apply_friction()
	host.apply_gravity(delta)
	host.apply_movement(delta)
	host.update_sprite()

func _enter_state(new_state, old_state):
	match new_state:
		"startup":
			host.gravity = Global.gravity
			host.prepare_to_attack()
		"idle":
			host.gravity = Global.gravity
			host.prepare_to_attack()
		"knockout":
			host.knock_out()
	
	if new_state in host.ai.ATTACKS:
		# IF Nolok is in an attacking state,
		
		# Wait until the attack completes,
		yield( host.call(new_state), "completed" )
		
		# Then if he's still in the same state, set his state to idle again
		if state == new_state:
			set_state("idle")
