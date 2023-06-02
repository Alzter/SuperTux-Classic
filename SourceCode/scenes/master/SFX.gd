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


extends Node2D

onready var host = get_parent()

func play(sound_to_play):
	# If the player object is playing this sound,
	# Use "Small" equivalents for sounds where possible
	# If Tux is small
	if host.is_in_group("players") and !host.is_in_group("worldmap"):
		var player_is_small = host.state == host.states.SMALL
		var has_small_sound = has_node(sound_to_play + "Small")
		
		if player_is_small and has_small_sound:
			sound_to_play = str(sound_to_play + "Small")
	
	if has_node(sound_to_play):
		var s = get_node(sound_to_play)
		if s:
			if s.bus == "Master":
				s.bus = "Sounds"
			s.play()

func stop(sound_to_stop):
	if has_node(sound_to_stop):
		var s = get_node(sound_to_stop)
		if s:
			s.stop()

func stop_all():
	for child in get_children():
		child.stop()
