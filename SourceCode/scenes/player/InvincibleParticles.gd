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
onready var particles = [$InvincibleBig, $InvincibleSmall, $InvincibleTrail]

func _process(delta):
	var invincible = host.invincible and host.invincible_type == host.invincible_types.STAR
	if invincible:
		var small = !host.has_large_hitbox
		var invincible_particle = $InvincibleSmall if small else $InvincibleBig
		var not_invincible_particle = $InvincibleSmall if !small else $InvincibleBig
		invincible_particle.emitting = true
		not_invincible_particle.emitting = false
		$InvincibleTrail.emitting = true
		$InvincibleTrail.position.y = 0 if small else -16
	else:
		if !$InvincibleTrail.emitting: return
		for node in particles:
			node.emitting = false
