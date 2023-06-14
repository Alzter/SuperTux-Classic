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


# =====================================================================================
# This node zooms in the screen by multiplying the pixel size at higher resolutions.
# It can be disabled by setting variable "enable_zoom_in" to false.

extends Node

var min_size = Vector2.ZERO

# If viewport is higher than this size, double the resolution
var ratio_size = Vector2(500, 480)
var ratio_size_mobile = Vector2(500, 400) # The ratio size is different on mobile devices

var screen_shrink = 1
var window_size = null
var window_resolution = null

signal window_resized

var enable_zoom_in = true setget _set_zoom_in

func _ready():
	get_viewport().connect("size_changed", self, "window_resized")
	window_resized()

func window_resized():
	
	var pixel_size = 1
	window_size = get_viewport().size
	var pixel_ratio = Vector2.ONE
	
	if enable_zoom_in:
		var ratio = ratio_size_mobile if OS.has_feature("mobile") else ratio_size
		
		pixel_ratio.x = floor(window_size.x / ratio.x)
		pixel_ratio.y = floor(window_size.y / ratio.y)
		
		pixel_size = min(pixel_ratio.x, pixel_ratio.y)
		pixel_size = max(pixel_size, 1)
	
	screen_shrink = pixel_size
	
	window_resolution = window_size / pixel_size

	
	get_tree().set_screen_stretch(SceneTree.STRETCH_ASPECT_IGNORE, SceneTree.STRETCH_ASPECT_IGNORE, min_size, pixel_size)
	emit_signal("window_resized")

func _set_zoom_in(new_value):
	enable_zoom_in = new_value
	window_resized()
