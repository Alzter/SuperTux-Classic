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

var BrickSmash = preload("res://scenes/particles/" + "BrickSmash" + ".tres")
var InvincibleParticlesBig = preload("res://scenes/particles/" + "InvincibleParticlesBig" + ".tres")
var InvincibleParticlesSmall = preload("res://scenes/particles/" + "InvincibleParticlesSmall" + ".tres")
var InvincibleParticlesTrail = preload("res://scenes/particles/" + "InvincibleParticlesTrail" + ".tres")
var SnowfallSmall = preload("res://scenes/particles/" + "SnowfallSmall" + ".tres")

var materials = [
	BrickSmash,
	InvincibleParticlesBig,
	InvincibleParticlesSmall,
	InvincibleParticlesTrail,
	SnowfallSmall,
]

func _ready(): # Make all of the game's particles emit once so they stay loaded
	for material in materials:
		var particles_instance = Particles2D.new()
		particles_instance.set_process_material(material)
		particles_instance.set_one_shot(true)
		particles_instance.set_emitting(true)
		particles_instance.modulate = Color(0,0,0,0) # Make them invisible so we don't actually see them
		self.add_child(particles_instance)
