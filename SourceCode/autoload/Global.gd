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


extends Node

var title_screen_scene = "res://scenes/menus/TitleScreen.tscn"
var level_editor_scene = "res://scenes/leveleditor/LevelEditor.tscn"

var current_scene = null
var current_level = null
var current_level_path = null

var player = null setget player_set
var spawn_position = null
var TILE_SIZE = 32
var base_gravity = 1 * pow(60, 2) / 3
var gravity = 1 setget _update_gravity
var fireballs_on_screen = 0 setget _change_fireball_count

var controls = ["jump", "run", "move_left", "move_right", "move_up", "duck"]

var can_pause = false

var privacy_policy_url = "https://github.com/Alzter/SuperTux-Classic/blob/main/PRIVACYPOLICY.md"

var level_attributes_cache = {}

signal level_loaded
signal player_loaded
signal level_ready # EMITS AFTER THE LEVEL TITLE CARD HAS DISAPPEARED
signal options_data_created

signal player_died
signal level_cleared

func _ready():
	self.gravity = 1
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	current_level_path = current_scene.filename
	
	if !SaveManager.does_options_data_exist():
		create_options_data()
		yield(self, "options_data_created")
	
	var options_data : Dictionary = SaveManager.get_options_data()
	apply_options(options_data)
	SaveManager.load_current_controls()

func _update_gravity(new_value):
	gravity = new_value * pow(60.0, 2.0) / 3.0

func respawn_player():
	if current_level == current_scene:
		goto_level(current_level_path)
	else:
		emit_signal("player_died")

func goto_level(path, reset_checkpoint = false):
	if path != current_level_path or reset_checkpoint:
		spawn_position = null
	
	if path != current_level_path: Scoreboard.number_of_deaths = 0
	
	goto_scene(path)

func goto_title_screen():
	goto_scene(title_screen_scene)

func goto_scene(path, loading_level = false):
	call_deferred("_deferred_goto_scene", path, loading_level)
	yield(self, "level_loaded")

func _deferred_goto_scene(path, loading_level = false):
	get_tree().paused = true
	Engine.time_scale = 1;
	# It is now safe to remove the current scene
	current_scene.free()
	current_level = null
	player = null
	
	# Load the new scene.
	var s = ResourceLoader.load(path)
	
	# Instance the new scene.
	current_scene = s.instance()
	
	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)
	current_level_path = current_scene.filename
	
	get_tree().paused = false
	emit_signal("level_loaded")

# Triggered once the player loads and executes their _ready() script. Sets the value of player to the player's node.
func player_set(new_value):
	player = new_value
	if spawn_position != null: player.set_position(spawn_position)
	
	emit_signal("player_loaded")

func _change_fireball_count(new_value):
	new_value = max(new_value, 0)
	fireballs_on_screen = new_value

func mute_sound_channel(channel_name, muted = true):
	var channel_id = AudioServer.get_bus_index(channel_name)
	if channel_id == -1: return
	AudioServer.set_bus_mute(channel_id, muted)

func hitstop(time, shake_intensity = 0, shake_damping = 0.8):
	if shake_intensity > 0:
		camera_shake(shake_intensity, shake_damping)
	
	if time > 0:
		Global.can_pause = false
		get_tree().paused = true
		yield(get_tree().create_timer(time, true), "timeout")
		get_tree().paused = false
		Global.can_pause = true

func camera_shake(intensity, damping):
	if intensity <= 0: return
	
	var camera = get_current_camera()
	if camera == null: return
	if !camera.has_method("camera_shake"): return
	
	camera.camera_shake(intensity, damping)

func get_current_camera():
	var viewport = get_viewport()
	if not viewport:
		return null
	var camerasGroupName = "__cameras_%d" % viewport.get_viewport_rid().get_id()
	var cameras = get_tree().get_nodes_in_group(camerasGroupName)
	for camera in cameras:
		if camera is Camera2D and camera.current:
			return camera
	return null

# Creates the options data file for future modification.
# This will reset the options file if it already exists.
func create_options_data():
	var options_data = {
		"music_volume" : -6.0,
		"sfx_volume" : 0.0,
		"ambience_volume" : 0.0,
	}
	SaveManager.save_options_data(options_data)
	yield(SaveManager, "save_completed")
	print("Created Options Data")
	emit_signal("options_data_created")

# Applies options from the options file into the game.
# E.g. sets the music volume to whatever the user previously set it to.
func apply_options(options_data : Dictionary):
	if SaveManager.does_options_data_exist():
		AudioServer.set_bus_volume_db(2, options_data["music_volume"])
		AudioServer.set_bus_volume_db(1, options_data["sfx_volume"])
		AudioServer.set_bus_volume_db(3, options_data["ambience_volume"])
		AudioServer.set_bus_volume_db(4, options_data["ambience_volume"])
		AudioServer.set_bus_volume_db(5, options_data["ambience_volume"])

func add_child_to_level(child_scene, owner):
	if current_level:
		current_level.add_child(child_scene)
		child_scene.set_owner(owner)
		return child_scene
	else:
		push_error("Error adding child scene to level - No current level exists!")
		return null

func level_completed():
	if current_level:
		if current_scene == current_level:
			if current_level.has_method("level_complete"):
				current_level.level_complete()
		else:
			emit_signal("level_cleared")

func save_node_to_directory(node : Node, dir : String):
	for child in node.get_children():
		child.owner = node
		for baby in child.get_children():
			baby.owner = node
	var packed_scene = PackedScene.new()
	packed_scene.pack(node)
	ResourceSaver.save(dir, packed_scene)

# Gets ALL children in a node, including children of children.
func get_all_children(node, array := []):
	array.push_back(node)
	for child in node.get_children():
		if !is_instance_valid(child): continue
		array = get_all_children(child,array)
	return array

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files

# Horrible jank. Will break easily. JANK IT UP!!
func load_level_editor_with_level(filepath_of_level_to_edit : String):
	yield(call("goto_scene", level_editor_scene), "completed")
	
	var editor = current_scene
	editor.call_deferred("load_level_from_path", filepath_of_level_to_edit)
	#editor.load_level_from_path(filepath_of_level_to_edit)

# Returns level attributes from whichever STC level you specify the directory of.
func get_level_attribute(level_filepath : String, attribute_to_get : String):
	# If we have already cached the level attribute, just use that instead and
	# don't waste time and memory loading a level scene.
	var cached_attributes_for_level = level_attributes_cache.get(level_filepath)
	if cached_attributes_for_level is Dictionary:
		var cached_attribute = cached_attributes_for_level.get(attribute_to_get)
		if cached_attribute:
			#print("Cached level attribute " + attribute_to_get)
			return cached_attribute
	
	#print("Uncached level attribute " + attribute_to_get)
	
	var level_instance = load(level_filepath).instance()
	var attribute_value = level_instance.get(attribute_to_get)
	level_instance.queue_free()
	
	# Cache the level attribute so we can access it faster if we need it again.
	var cache = level_attributes_cache.get(level_filepath)
	if cache:
		cache[attribute_to_get] = attribute_value
	else:
		var attribute = {attribute_to_get : attribute_value}
		level_attributes_cache[level_filepath] = attribute
	
	return attribute_value

func clear_level_cache(level_filepath : String):
	level_attributes_cache.erase(level_filepath)
