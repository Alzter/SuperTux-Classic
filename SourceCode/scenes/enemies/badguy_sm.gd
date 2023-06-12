#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2000 Bill Kendrick <bill@newbreedsoftware.com>
#  Copyright (C) 2004 Tobias Glaesser <tobi.web@gmx.de>
#  Copyright (C) 2004 Matthias Braun <matze@braunis.de>
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
	add_state("walk")
	add_state("squished")
	add_state("kicked")
	add_state("grabbed")
	add_state("explode")
	add_state("dead")
	add_state("bounce_up")
	add_state("bounce_forward")
	add_state("fly")
	add_state("fall")
	add_state("water_submerged")
	
	# What initial state to use for the enemy depends on its type
	match host.type:
		"Fish":
			call_deferred("set_state", "fall")
		"Jumpy": # Jumpy goes to a bouncing state
			call_deferred("set_state", "bounce_up")
		"Bouncing": # Bouncing snowball bounces forwards
			call_deferred("set_state", "bounce_forward")
		"Flying": # Bouncing snowball bounces forwards
			call_deferred("set_state", "fly")
		_: # All other walking enemies use the default walking state
			call_deferred("set_state", "walk")

func _state_logic(delta):
	match state:
		"water_submerged": return
		"fly":
			host.flying_movement(delta)
			host.jumpy_movement()
			return
		"bounce_up":
			host.jumpy_bounce()
			host.apply_gravity(delta)
			host.jumpy_movement()
			host.update_sprite()
			return
		"fall":
			host.apply_gravity(delta)
			host.jumpy_movement(true)
			host.update_sprite()
			host.check_water_below(delta)
			return
		"bounce_forward":
			host.move_forward(true, false, host.bounce_move_speed)
			host.jumpy_bounce()
			host.apply_gravity(delta)
			host.jumpy_movement()
			host.update_sprite()
			return
		"grabbed":
			host.update_sprite()
			return
		"walk":
			host.move_forward(host.turn_on_walls, host.turn_on_cliffs)
		"kicked":
			host.kicked_movement()
			host.hit_blocks(delta)
		"dead":
			host.apply_gravity(delta)
			host.apply_movement(delta, false)
			return
		"explode":
			return
	
	host.update_sprite()
	host.apply_gravity(delta)
	host.apply_movement(delta)

func _get_transition(delta):
	match state:
		"fall":
			if host.velocity.y <= 0: return "bounce_up"
		"bounce_up":
			if host.velocity.y > 0 and host.type != "Jumpy": return "fall"

func _enter_state(new_state, old_state):
	match new_state:
		"fall":
			host.disable_bounce_area(false)

func _exit_state(old_state, new_state):
	pass
