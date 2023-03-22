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

export var is_worldmap = false
export var level_dot_scene : PackedScene
var text = ""
var unknown_objects = []

onready var object_map = null
onready var import = null

var object_types = {
	"spiky" : "BadSpiky",
	"snowball" : "BadSnowball",
	"mriceblock" : "BadIceblock",
	"mrbomb" : "BadBomb",
	"bouncingsnowball" : "BadBouncing",
	"flyingsnowball" : "BadFlying",
	"stalactite" : "BadStalactite",

	"money" : "BadJumpy",
	"jumpy" : "BadJumpy",
	"flame" : "BadFlame",

	"point" : "!Checkpoint",
	"level" : "level",
}

# Translates parameters from Milestone 1's leveldot objects into STC's leveldot objects.
var leveldot_parameters = {
	"name" : "level_file_path",
	"extro-filename" : "extro_level_file_path",
	"teleport-message" : "message",
	"map-message" : "message",
	"dest_x" : "teleport_location.x",
	"dest_y" : "teleport_location.y",
}

func import_worldmap_objects(object_string, object_node):
	if object_string == "" or object_string == null: return
	var objects = _object_list_to_array(object_string)
	_place_worldmap_objects(objects, object_node)

func import_objects(object_string, object_map):
	if object_string == "" or object_string == null: return
	var objects = _object_list_to_array(object_string)
	_place_objects_in_level(objects, object_map)

func _get_tile_id_from_name(tile_name, tilemap_to_use = object_map):
	return import.get_tile_id_from_name(tile_name, tilemap_to_use)

func _object_list_to_array(object_string):
	text = ""
	
	var object_array = []
	for i in object_string.length():
		var item = object_string.substr(i, 1)
		
		if item == "(":
			var string_to_add = text.strip_edges(true,true)
			if string_to_add != "": object_array.append(string_to_add)
			text = ""
		else:
			if item != ")":
				text = text + item
	
	if text != "":
		var string_to_add = text.strip_edges(true,true)
		if string_to_add != "": object_array.append(string_to_add)
	
	var obj_array = []
	var array = []
	
	for i in object_array:
		if object_types.has(i):
			if array != []:
				obj_array.append(array)
			array = []
		#else:
		#	if !unknown_objects.has(i): unknown_objects.append(i)
		
		var first_letter = i.substr(0, 1)
		if ["x", "y"].has(first_letter):
			i = i.substr(2, i.length() - 2)
		
		array.append(i)
	
	if array != []:
		obj_array.append(array)
	
	return obj_array

func _place_worldmap_objects(obj_array, object_node : Node):
	# For every level dot in the worldmap
	# They have the format [level, name "world/level.stl", X, Y, other_parameter "value"]
	var count = 0
	for i in obj_array:
		count += 1
		var position = Vector2(i[2], i[3])
		
		# Create the level dot object for the level dot and add it to the scene
		var leveldot = level_dot_scene.instance()
		object_node.add_child(leveldot)
		leveldot.name = "LevelDot" + str(count)
		leveldot.position = position * 32
		leveldot.set_owner(object_node)
		
		var regex = RegEx.new()
		regex.compile('(\\D+) "(.+)"')
		
		# Use a Regex to capture all string parameters in the level dot object
		for j in i:
			var result = regex.search(j)
			if result:
				var parameter_name = result.get_strings()[1] # name
				var parameter_value = result.get_strings()[2] # world1/level1.stl
				
				if leveldot_parameters.has(parameter_name):
					var parameter_to_get = leveldot_parameters.get(parameter_name)
					var parameter_to_change = leveldot.get(parameter_to_get)
					parameter_to_change = parameter_value
				else:
					print("Unrecognised Level Dot Parameter: " + parameter_name)
		
		
		return
	return

func _place_objects_in_level(obj_array, objmap_to_use):
	for i in obj_array:
		var obj_offset = Vector2(0,0)
		var type = i[0]
		var position = Vector2(i[1], i[2])
		
		if object_types.has(type):
			type = object_types.get(type)
			obj_offset = _get_object_offset(type)
			var tile_to_set = _get_tile_id_from_name(type, objmap_to_use)
			var pos = objmap_to_use.world_to_map(position)
			pos += obj_offset
			
			objmap_to_use.set_cell(pos.x + 1, pos.y, tile_to_set, true)
		else:
			if !unknown_objects.has(type): unknown_objects.append(type)
	
	if unknown_objects != []:
		print("The following objects were not found:")
		print(unknown_objects)

func _get_object_offset(object_type):
	if object_type == "BadFlame":
		print(object_type)
		return Vector2(-1, 0)
	else: return Vector2.ZERO

func _save_node_to_directory(node, dir):
	import.save_node_to_directory(node, dir)
