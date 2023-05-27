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


extends Camera2D

onready var host = get_parent()
onready var noise = OpenSimplexNoise.new()
onready var tween = $Tween
var noise_y = 0

var intensity = 0
export var min_intensity = 0.05 # If intensity is below this threshold, stop shaking
export var shake_dampen_default = 0.8

onready var dampen = shake_dampen_default

var pos_offset = 1 * Global.TILE_SIZE

var current_offset = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func _process(_delta):
	# Extended Camera Stuff
	position = Vector2.ZERO
	
	var offset_to_use = pos_offset * sign(host.facing)
	
	var lerp_speed = abs(host.velocity.x) * 0.0001
	lerp_speed = clamp(lerp_speed, 0, 1)
	
	if lerp_speed > 0:
		current_offset = lerp(current_offset, offset_to_use, lerp_speed)
	offset.x = current_offset
	
	position += offset
	offset = Vector2.ZERO
	
	# Camera shake stuff
	intensity *= dampen
	if intensity < min_intensity: intensity = 0
	if intensity > 0: _shake()

func _shake():
	noise_y += 1
	offset.x = intensity * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = intensity * noise.get_noise_2d(noise.seed*3, noise_y)

func camera_shake(new_value, dampening = shake_dampen_default):
	if dampening == null: dampening = shake_dampen_default
	intensity = new_value
	dampen = dampening

func smooth_zoom(zoom_level : float, zoom_duration : float):
	var zoom_vec = Vector2.ONE * zoom_level
	tween.interpolate_property(self, "zoom", zoom, zoom_vec, zoom_duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()
