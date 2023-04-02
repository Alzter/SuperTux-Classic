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

var world = null

var object_types = {
	"spiky" : "BadSpiky",
	"snowball" : "BadSnowball",
	"mriceblock" : "BadIceblock",
	"mrbomb" : "BadBomb",
	"bouncingsnowball" : "BadBouncing",
	"flyingsnowball" : "BadFlying",
	"stalactite" : "BadStalactite",
	"fish" : "BadFish",

	"money" : "BadJumpy",
	"jumpy" : "BadJumpy",
	"flame" : "BadFlame",

	"point" : "!Checkpoint",
	"level" : "level",
}

var smart_enemies = {
	"BadSnowball" : "BadSmartball",
	"BadIceblock" : "BadSmartblock",
}

# Translates parameters from Milestone 1's leveldot objects into STC's leveldot objects.
var leveldot_parameters = {
	"x" : "position.x",
	"y" : "position.y",
	"name" : "level_file_path",
	"extro-filename" : "extro_level_file_path",
	"teleport-message" : "message",
	"map-message" : "map_message",
	"dest_x" : "teleport_location.x",
	"dest_y" : "teleport_location.y",
	"invisible-teleporter" : "invisible",
}

func import_worldmap_objects(object_string, object_node):
	if object_string == "" or object_string == null: return
	var objects = _object_list_to_array(object_string, false)
	_place_worldmap_objects(objects, object_node)

func import_objects(object_string, object_map):
	if object_string == "" or object_string == null: return
	var objects = _object_list_to_array(object_string)
	_place_objects_in_level(objects, object_map)

func _get_tile_id_from_name(tile_name, tilemap_to_use = object_map):
	return import.get_tile_id_from_name(tile_name, tilemap_to_use)

func _object_list_to_array(object_string, contract_xy_positions = true):
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
		
		if contract_xy_positions:
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
	var teleporters = 1
	var messages = 1
	
	for i in obj_array:
		count += 1
		#var position = Vector2(i[2], i[3])
		
		# Create the level dot object for the level dot and add it to the scene
		var leveldot = level_dot_scene.instance()
		object_node.add_child(leveldot)
		
		var regex = RegEx.new()
		regex.compile('([^ ]+) (.+)')
		
		# Use a Regex to capture all string parameters in the level dot object
		for j in i:
			var result = regex.search(j)
			if result:
				var parameter_name = result.get_strings()[1] # name
				var parameter_value = result.get_strings()[2] # world1/level1.stl
				
				# If the parameter value is encased in quotes like "this"
				if parameter_value.begins_with("\""):
					# Remove the quotes and treat it as a string.
					parameter_value = parameter_value.replace("\"", "")
				else:
					# Otherwise, convert it to an integer
					parameter_value = int(parameter_value)
				
				if leveldot_parameters.has(parameter_name):
					var parameter_to_get = leveldot_parameters.get(parameter_name)
					parameter_value = _handle_leveldot_parameter(parameter_to_get, parameter_value, leveldot)
					leveldot.set(parameter_to_get, parameter_value)
				else:
					print("Unrecognised Level Dot Parameter: " + parameter_name)
		
		if leveldot.level_file_path == "":
			if leveldot.teleport_location != Vector2.ZERO:
				leveldot.name = "Teleporter" + str(teleporters)
				teleporters += 1
			else:
				leveldot.name = "Message" + str(messages)
				messages += 1

# This function converts the parameters from level dots in SuperTux worldmaps
# into SuperTux Classic's format.
func _handle_leveldot_parameter(parameter_name, parameter_value, leveldot):
	match parameter_name:
		"position.x":
			leveldot.position.x = parameter_value * 32 + 16
			return
		"position.y":
			leveldot.position.y = parameter_value * 32 + 16
			return
		
		"teleport_location.x":
			leveldot.is_teleporter = true
			leveldot.teleport_location.x = parameter_value
			return
		"teleport_location.y":
			leveldot.is_teleporter = true
			leveldot.teleport_location.y = parameter_value
			return
		
		"map_message":
			leveldot.message = parameter_value
			leveldot.invisible = true
			return
		
		# Converts level file paths
		# e.g. "world1/level26.stl"
		# Into a path readable by Godot
		# e.g. "res://scenes/levels/world1/level26.tscn"
		"level_file_path":
			var filepath_splitter = RegEx.new()
			filepath_splitter.compile('(\\D+\\d+)\\/(\\D+\\d+).stl')
			
			var result = filepath_splitter.search(parameter_value)
			if result:
				var level_folder = result.get_strings()[1]
				var level_filename = result.get_strings()[2]
				leveldot.name = level_filename
				world = level_folder
				var new_level_file_path = "res://scenes/levels/" + level_folder + "/" + level_filename + ".tscn"
				return new_level_file_path
			else:
				push_error("Unable to parse level file path: " + parameter_value)
		
		# Converts level extro file paths from
		# "extro.txt"
		# to "res://scenes/levels/world1/extro.tscn"
		# using the world folder variable we stored from the last level
		"extro_level_file_path":
			var extro_filename_splitter = RegEx.new()
			extro_filename_splitter.compile('(\\D+)\\.')
			var result = extro_filename_splitter.search(parameter_value)
			
			if result:
				var extro_level_filename = result.get_strings()[1]
				var extro_level_file_path = "res://scenes/levels/" + world + "/" + extro_level_filename + ".tscn"
				return extro_level_file_path
			else:
				push_error("Unable to parse level extro file path: " + parameter_value)
	
	# Failsafe incase the value is not handled
	print("Level dot parameter not handled: " + parameter_name)
	return parameter_value

func _place_objects_in_level(obj_array, objmap_to_use):
	for i in obj_array:
		if i.size() <= 1: break
		var obj_offset = Vector2(0,0)
		var type = i[0]
		var position = Vector2(int(i[1]), int(i[2]))
		
		var stay_on_platform = i.has("stay-on-platform #t")
		
		if object_types.has(type):
			
			type = object_types.get(type)
			
			if stay_on_platform and smart_enemies.has(type):
				type = smart_enemies.get(type)
			
			#print(type)
			
			obj_offset = _get_object_offset(type)
			var tile_to_set = _get_tile_id_from_name(type, objmap_to_use)
			position.x = round(position.x / 32.0) * 32.0
			position.y = round(position.y / 32.0) * 32.0
			var pos = objmap_to_use.world_to_map(position)
			pos += obj_offset
			
			var tile_occupied = objmap_to_use.get_cell(pos.x, pos.y) != -1
			if tile_occupied:
				print("Object overlap at X: " + str(pos.x) + " Y: " + str(pos.y))
				pos.y -= 1
			
			objmap_to_use.set_cell(pos.x, pos.y, tile_to_set, true)
		else:
			if !unknown_objects.has(type): unknown_objects.append(type)
	
	if unknown_objects != []:
		print("The following objects were not found:")
		print(unknown_objects)

func _get_object_offset(object_type):
	if object_type == "BadFlame":
		#print(object_type)
		return Vector2.ZERO
	else: return Vector2.ZERO

func _save_node_to_directory(node, dir):
	import.save_node_to_directory(node, dir)
