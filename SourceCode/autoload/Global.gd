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

enum POWERUP_STATES {Small, Big, Fire}
enum REBIND_TYPE {None, Key, Gamepad}

const empty_level_path_string = "[LevelPath]"

var title_screen_scene = "res://scenes/menus/TitleScreen.tscn"
var level_editor_menu_scene = "res://scenes/leveleditor/menus/MainMenu.tscn"
var level_editor_scene = "res://scenes/leveleditor/LevelEditor.tscn"

var worlds_folder = "res://scenes/levels/"

var layer_icons_directory = "res://images/editor/layer_icons/"

var current_scene = null
var current_level = null
var current_level_path = null

var player = null setget player_set
var spawn_position = null
var TILE_SIZE = 32
var base_gravity = 1 * pow(60, 2) / 3
var gravity = 1 setget _update_gravity
var fireballs_on_screen = 0 setget _change_fireball_count
var auto_run = true

var controls = ["jump", "run", "move_left", "move_right", "move_up", "duck"]

var can_pause = false

var privacy_policy_url = "https://github.com/Alzter/SuperTux-Classic/blob/main/PRIVACYPOLICY.md"

var level_attributes_cache = {}

var is_in_editor = false setget , _get_is_in_editor

var accepted_music_file_types = [".mp3", ".wav", ".ogg"]

#var hovered_objects = []

signal scene_loaded
signal player_loaded
signal level_ready # EMITS AFTER THE LEVEL TITLE CARD HAS DISAPPEARED
signal options_data_created

signal player_died
signal level_cleared

signal object_clicked

signal quit_game_requested

# When in the level editor main menu, this signal opens the World Menu for a given world
signal open_world_menu(world_folder_name)

func _ready():
	# Disable the game automatically quitting
	get_tree().set_auto_accept_quit(false)
	
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

func goto_level_editor_main_menu():
	goto_scene(level_editor_menu_scene)

func goto_level_editor_world_menu(world_folder_name : String):
	yield(call("goto_scene", level_editor_menu_scene), "completed")
	
	emit_signal("open_world_menu", world_folder_name)

func goto_scene(path, loading_level = false):
	if !string_is_scene_path(path):
		push_error("Scene not found at path: " + path)
		return
	
	call_deferred("_deferred_goto_scene", path, loading_level)
	yield(self, "scene_loaded")

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
	emit_signal("scene_loaded")

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
	
	var pause_enabled = Global.can_pause
	if time > 0:
		Global.can_pause = false
		get_tree().paused = true
		yield(get_tree().create_timer(time, true), "timeout")
		get_tree().paused = false
		if pause_enabled: Global.can_pause = true

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
		"auto_run" : true,
	}
	SaveManager.save_options_data(options_data)
	yield(SaveManager, "save_completed")
	print("Created Options Data")
	emit_signal("options_data_created")

# Applies options from the options file into the game.
# E.g. sets the music volume to whatever the user previously set it to.
func apply_options(options_data : Dictionary):
	if SaveManager.does_options_data_exist():
		print("Applying Options Data:")
		print(options_data)
		print()
		
		if options_data.has("music_volume"):
			AudioServer.set_bus_volume_db(2, options_data["music_volume"])
		
		if options_data.has("sfx_volume"):
			AudioServer.set_bus_volume_db(1, options_data["sfx_volume"])
		
		if options_data.has("ambience_volume"):
			AudioServer.set_bus_volume_db(3, options_data["ambience_volume"])
			AudioServer.set_bus_volume_db(4, options_data["ambience_volume"])
			AudioServer.set_bus_volume_db(5, options_data["ambience_volume"])
		
		if options_data.has("auto_run"): auto_run = options_data["auto_run"]

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
	var err = ResourceSaver.save(dir, packed_scene)
	if err != OK:
		var error_msg = str("Error saving node: " + str(node) + " at directory: " + dir + " Error code: " + str(err))
		push_error(error_msg)
		print(error_msg)
	return err

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
	if !string_is_scene_path(filepath_of_level_to_edit):
		push_error("Level not found at path: " + filepath_of_level_to_edit)
		return
	
	yield(call("goto_scene", level_editor_scene), "completed")
	
	UserLevels.current_level = filepath_of_level_to_edit
	var editor = current_scene
	editor.call_deferred("load_level_from_path", filepath_of_level_to_edit)
	#editor.load_level_from_path(filepath_of_level_to_edit)

# Returns true if a string is a path to a level file.
# E.g. "res://scenes/levels/world1/level1.tscn"
func string_is_scene_path(string : String):
	if string == empty_level_path_string: return true
	
	# If the string specifies a file path to a scene file
	if string.ends_with(".tscn"):
		
		# If the file exists, return true.
		var f = File.new()
		return f.file_exists(string)
	
	return false

# Returns level attributes from whichever STC level you specify the directory of.
func get_level_attribute(level_filepath : String, attribute_to_get : String):
	if level_filepath == empty_level_path_string:
		return "Select a level..."
	
	# If we have already cached the level attribute, just use that instead and
	# don't waste time and memory loading a level scene.
	
	var cached_attribute = _get_cached_level_attribute(level_filepath, attribute_to_get)
	if cached_attribute != null: return cached_attribute
	
	#print("Uncached level attribute " + attribute_to_get)
	
	var level_instance = load(level_filepath).instance()
	#print("Loading level " + level_filepath)
	var attribute_value = level_instance.get(attribute_to_get)
	level_instance.queue_free()
	
	# Cache the level attribute so we can access it faster if we need it again.
	_cache_level_attribute(level_filepath, attribute_to_get, attribute_value)
	
	return attribute_value

# Gets multiple attributes from a level (e.g. "level_title" and "level_author") as a string array.
# This is more efficient than running get_level_attribute for every attribute.
func get_level_attributes(level_filepath : String, attributes_to_get : Array) -> Array:
	var attributes = []
	var level_instance = null
	
	# For every level attribute:
	for attribute in attributes_to_get:
		
		# If we have it cached, use the cached version
		var cached_attribute = _get_cached_level_attribute(level_filepath, attribute)
		if cached_attribute: attributes.append(cached_attribute)
		
		else:
			# Otherwise load the level and get it from there.
			if !level_instance:
				level_instance = load(level_filepath).instance()
				#print("Loading level " + level_filepath)
			
			# Get the attribute from the level itself.
			var attribute_value = level_instance.get(attribute)
			attributes.append(attribute_value)
			
			# Cache it for faster future access.
			_cache_level_attribute(level_filepath, attribute, attribute_value)
	
	# If we needed to load the level to get the attributes, free it from memory now.
	if level_instance: level_instance.queue_free()
	return attributes

func clear_level_cache(level_filepath : String):
	level_attributes_cache.erase(level_filepath)


func _get_cached_level_attribute(level_filepath : String, attribute_to_get : String):
	var cached_attributes_for_level = level_attributes_cache.get(level_filepath)
	if cached_attributes_for_level is Dictionary:
		var cached_attribute = cached_attributes_for_level.get(attribute_to_get)
		if cached_attribute:
			#print("Cached level attribute " + attribute_to_get)
			return cached_attribute
	return null

func _cache_level_attribute(level_filepath : String, attribute_to_get : String, attribute_value):
	var cache = level_attributes_cache.get(level_filepath)
	
	if cache:
		cache[attribute_to_get] = attribute_value
	else:
		var attribute = {attribute_to_get : attribute_value}
		level_attributes_cache[level_filepath] = attribute

func object_clicked(object : Node, click_type : int):
	emit_signal("object_clicked", object, click_type)

func _get_is_in_editor():
	if !current_level: return false
	return current_level != current_scene

# Returns an array of file paths for all scene files found within a folder.
func get_all_scene_files_in_folder(folder_name : String):
	
	# Add a / at the end of the folder name if it doesn't exist
	if !folder_name.ends_with("/"): folder_name = folder_name + "/"
	
	var object_file_list = []
	var dir = Directory.new()
	
	if !dir.dir_exists(folder_name): return null
	else:
		var object_files = Global.list_files_in_directory(folder_name)
		
		for file in object_files:
			if file.ends_with(".tscn"):
				var file_path = folder_name + file
				object_file_list.append(file_path)
	
	return object_file_list

static func copy_directory_recursively(p_from : String, p_to : String) -> int:
	var directory = Directory.new()
	if not directory.dir_exists(p_to):
		directory.make_dir_recursive(p_to)
	
	var open_status = directory.open(p_from)
	
	if open_status == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while (file_name != "" && file_name != "." && file_name != ".."):
			if directory.current_is_dir():
				copy_directory_recursively(p_from + "/" + file_name, p_to + "/" + file_name)
			else:
				directory.copy(p_from + "/" + file_name, p_to + "/" + file_name)
			file_name = directory.get_next()
	else:
		push_error("Error copying " + p_from + " to " + p_to)
		return open_status
	
	return OK

# Converts a local reference in the project files ("res://") or user directory ("user://")
# to an absolute file path.

static func globalise_path(local_path : String):
	
	if local_path.begins_with("res://"):
		if OS.has_feature("editor"): return local_path
		
		var file_path = local_path.trim_prefix("res://")
		
		var global_path = OS.get_executable_path().get_base_dir()
		
		push_error(OS.get_executable_path())
		push_error(global_path)
		
		if !global_path.ends_with("/"): global_path += "/"
		
		global_path += file_path
		
		push_error(global_path)
		
		return global_path
	
	elif local_path.begins_with("user://"):
		var file_path = local_path.trim_prefix("user://")
		
		var global_path = OS.get_user_data_dir()
		if !global_path.ends_with("/"): global_path += "/"
		
		global_path += file_path
		return global_path
	
	else: return null

# Recursive function to determine whether there is currently a Popup
# node visible within the current scene.
func is_popup_visible(node = current_scene):
	
	var popup_open = false
	for child in node.get_children():
		var open = is_popup_visible(child)
		if open == true: return true
	
	return _is_open_dialog(node)

func _is_open_dialog(node):
	if node is Popup:
		return node.visible
	else: return false

# Override the default quitting behaviour
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if self.is_in_editor:
			emit_signal("quit_game_requested")
		else:
			get_tree().quit() # default behavior

# Takes in an image texture given from a file path,
# and returns an ImageTexture object with the image as its texture
func load_external_image_texture(path_to_image : String):
	var image = Image.new()
	var err = image.load(path_to_image)
	if err != OK:
		push_error("Error loading image texture from file: " + path_to_image + " Error code: " + str(err))
		return null
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

# Better alphabetical sort algorithm that is used to sort level files.

# If two strings have numbers at the end (e.g. "level10", "level12"),
# Rather than sorting the two alphabetically,
# the string with the lowest number precedes the one with the highest.

# Normal sorting algorithm:
# "level1" "level10" "level11" "level12" "level13" ... "level2" "level21" "level22"...

# This sorting algorithm:
# "level1" "level2" "level3" "level4" "level5" "level6" ...

func sort_alphabetically(a, b):
	if a is String and b is String:
		
		# Remove file extensions from strings
		if a.get_extension(): a = a.trim_suffix("." + a.get_extension())
		if b.get_extension(): b = b.trim_suffix("." + b.get_extension())
		
		#if b.get_extension(): b.trim_suffix("." + b.get_extension())
		
		var end_num_a = ""
		var end_num_b = ""
		
		# If string A has a number at the end (e.g. "level27"),
		# Store that number in string str_num_a (e.g. "27")
		for character in a: if character.is_valid_integer(): end_num_a += character
		
		if end_num_a != "": a = a.trim_suffix(end_num_a)
		
		for character in b: if character.is_valid_integer(): end_num_b += character
		if end_num_b != "": b = b.trim_suffix(end_num_b)
		
		# If both strings are the same with end numbers removed:
		# E.g. "level25", "level21" become "level" and "level"
		if a == b:
			
			# We compare the two strings by how high the number at the end is instead.
			return int(end_num_a) < int(end_num_b)
		else:
			return a < b
		
		#print("=====")
		
		#for character in b:
		#	print(character)
		
	else:
		return a < b

# Loads in an audio file (MP3, OGG, or WAV) and converts it into an
# Audio Stream which can be played by an AudioStreamPlayer node.
func get_audio_stream_from_audio_file(audio_file_path : String, loop_audio : bool = true, loop_offset : float = 0.0):
	var f = File.new()
	
	if f.file_exists(audio_file_path):
		
		# Ensure the music file has a valid file extension
		var file_type = audio_file_path.get_extension()
		if file_type == "":
			push_error("Error loading song from file: " + audio_file_path + " - Song file extension not found")
			return null
		
		# Ensure the music file is of a type which is accepted by the game
		file_type = "." + file_type
		if !Global.accepted_music_file_types.has(file_type):
			push_error("Error loading song from file: " + audio_file_path + " - Song file type not supported")
			return null
		
		var buffer = null
		
		# For MP3/OGG files: open the song, read the data, and then close it
		if [".mp3", ".ogg"].has(file_type):
			
			f.open(audio_file_path, f.READ)
			buffer = f.get_buffer(f.get_len())
			f.close()
		
			if !buffer:
				push_error("Error loading song from file: " + audio_file_path + " - Song data (buffer) not found")
				return null
		
		var stream : AudioStream = null
		
		# ADD LOOP OFFSET CODE HERE
		match file_type:
			".mp3":
				stream = AudioStreamMP3.new()
				stream.set_data(buffer)
			".ogg":
				
				stream = AudioStreamOGGVorbis.new()
				stream.set_data(buffer)
			
			# We have to do an entirely different method to load audio
			# from wave files for some reason. Thanks to Giannino Clemente
			# for supplying this code at https://github.com/Gianclgar/GDScriptAudioImport
			".wav":
				var wav_loader = AudioLoader.new()
				stream = wav_loader.load_file(audio_file_path, loop_audio, loop_offset)
			
			"_":
				push_error("Error loading song from file: " + audio_file_path + " - Song file type not supported")
				return null
		
		if loop_audio:
			if [".mp3", ".ogg"].has(file_type):
				stream.set_loop(true)
				stream.set_loop_offset(loop_offset)
		
		print("Loaded custom music track.")
		return stream
