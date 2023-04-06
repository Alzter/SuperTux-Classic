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
	add_state("waiting")
	add_state("idle")
	add_state("squished")
	add_state("fake_death")
	add_state("phase_two_transition")
	add_state("defeated")
	
	# ATTACKS
	add_state("chomp")
	add_state("black_hole")
	
	# Don't do anything until the level title card is gone
	yield(Global, "level_ready")
	
	host.player = Global.player
	call_deferred("set_state", "waiting")
	
	yield(get_tree().create_timer(1), "timeout")
	
	if host.enabled:
		host.enable()
		
		if host.phase == 2: host.commence_phase_two()

func _state_logic(delta):
	host.set_anger()
	
	match state:
		"idle":
			host.idle_loop(delta)
		"fake_death":
			host.fake_death_loop(delta)
	
	host.update_sprite()

func _enter_state(new_state, old_state):
	if new_state == "idle":
		host.idle_animation()
	else:
		if host.anim_player.has_animation(new_state):
			host.anim_player.play(new_state)
	
	if new_state in host.ai.ATTACKS:
		# IF Grumbel is in an attacking state,
		
		# Execute the attack and wait until it finishes
		yield( host.call(new_state), "completed" )
		
		# Then if he's still in the same state, set his state to idle again
		if state == new_state:
			set_state("idle")
	
	elif host.has_method(new_state): host.call(new_state)

func _exit_state(old_state, new_state):
	match old_state:
		"squished":
			host.set_invincible()
