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


# State Machine code taken from Game Endeavor's tutorial on the subject
# https://www.youtube.com/watch?v=BNU8xNRk_oU
# Thanks Game Endeavor!!!! -Alzter

extends Node
class_name StateMachine

var state = null setget set_state
var previous_state = null
var states = []

onready var host = get_parent()

func _physics_process(delta):
	if host.has_node("VisibilityEnabler2D"): # Disable node functioning if it has VisibilityEnabler2D
		if !host.get_node("VisibilityEnabler2D").is_on_screen(): return
	
	if state != null:
		_state_logic(delta)
		var transition = _get_transition(delta)
		if transition != null:
			set_state(transition)


func _state_logic(delta):
	pass


func _get_transition(delta):
	return null


func _enter_state(new_state, old_state):
	pass


func _exit_state(old_state, new_state):
	pass


func set_state(new_state):
	previous_state = state
	state = new_state
	
	if previous_state != null:
		_exit_state(previous_state, state)
	if new_state != null:
		_enter_state(state, previous_state)


func add_state(state_name):
	states.append(state_name)
