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


# The only reason this scene exists is because if we don't pre-load our
# particle materials, they cause a lag spike when appearing for the first time
# in game. (sad godot bruh moment) Huge props to Travis Maynard for the fix.
# https://travismaynard.com/writing/caching-particle-materials-in-godot


extends CanvasLayer

var particles_dir = "res://scenes/particles/"

func _ready(): # Make all of the game's particles emit once so they stay loaded
	var particle_files = Global.list_files_in_directory(particles_dir)
	for particle_file in particle_files:
		var path = particles_dir + particle_file
		var particle = load(path)
		var particles_instance = Particles2D.new()
		particles_instance.set_process_material(particle)
		particles_instance.set_one_shot(true)
		particles_instance.set_emitting(true)
		particles_instance.modulate = Color(0,0,0,0) # Make them invisible so we don't actually see them
		self.add_child(particles_instance)
		particles_instance.position = Vector2(320,240)
		


