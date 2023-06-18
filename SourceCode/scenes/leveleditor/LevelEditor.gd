extends Control

#export var level_to_load = "res://scenes/levels/world1/level1.tscn"

export var object_scene_folder_for_levels = "res://scenes/objects/"
export var object_scene_folder_for_worldmaps = "res://scenes/worldmap/"

# The folder which contains all scenes for the objects
var object_scenes_folder = null setget , _get_object_scenes_folder

# The Editor UI gets smaller when the screen resolution is lower than this
export var ui_scale_min_resolution = Vector2(1280, 720)

var cache_level = null
var is_paused = false

export var unselected_tilemap_opacity = 0.5

export var editor_layers_directory = "res://scenes/layers/"

onready var sfx = $SFX

onready var toggle_edit_button = $UI/Scale/EditToggle

onready var tile_functions = $TileFunctions
onready var object_functions = $ObjectFunctions
onready var editor_camera = $EditorCamera

onready var ui_scale = $UI/Scale
onready var ui_editor = $UI/Scale/EditorUI
onready var tiles_container = $UI/Scale/EditorUI/TilesPanelOffset/TilesPanel/ScrollContainer/TilesContainer
onready var layers_container = $UI/Scale/EditorUI/LayersPanelOffset/LayersPanel/ScrollContainer/LayersContainer

var unsaved_changes = false
var rect_select_enabled = false setget update_rect_select_enabled
var eraser_enabled = false setget update_eraser_enabled
var eyedropper_enabled = false setget update_eyedropper_enabled
var flip_tiles_enabled = false setget update_flip_tiles_enabled
var edit_objects_enabled = false setget update_edit_objects_enabled

onready var tile_buttons = $UI/Scale/EditorUI/TilesPanelOffset/TilesPanel/PlacementOptionsContainer/PlacementOptions
onready var button_rect_select = tile_buttons.get_node("RectSelect")
onready var button_eraser = tile_buttons.get_node("Eraser")
onready var button_eyedropper = tile_buttons.get_node("EyeDropper")
onready var button_flip_tiles = tile_buttons.get_node("FlipTiles")
onready var button_edit_objects = tile_buttons.get_node("EditObject")

onready var button_undo = $UI/Scale/EditorUI/ButtonsContainer/Buttons/UndoButton
onready var button_level_properties = $UI/Scale/EditorUI/ButtonsContainer/Buttons/LevelProperties

onready var level_properties_dialog = $UI/Scale/EditorUI/LevelPropertiesDialog

export var layer_button_scene : PackedScene

#onready var cache_level_path = cache_level_directory + cache_level_filename

onready var edit_layer_dialog = $UI/Scale/EditorUI/EditLayerDialog

# This dialog appears if you attempt to close the level editor with unsaved changes.
onready var quit_without_saving_dialog = $UI/UnsavedChangesDialog

onready var pause_menu = $PauseMenu

signal level_loaded

signal eraser_toggled
signal rect_select_toggled
signal eyedropper_toggled
signal flip_tiles_toggled
signal edit_objects_toggled

var level = null
var level_objects = null setget , _get_level_objects
var object_map = null

var selected_layer = null setget update_selected_layer
var selected_layer_name = ""

var current_tile_id = -1 setget _update_current_tile_id # The ID of the tile the user is currently using
var current_object_resource = null setget _update_current_object_resource # The Resource of the object the user currently has selected

var edit_mode = true setget _update_edit_mode

var can_place_tiles = true setget , _get_can_place_tiles

var mouse_over_ui = null setget , _get_mouse_over_ui

var edit_dialog_visible = false

var layer_types = []

var undo_stack = []

# Dictionary {TileSet: int}
# Stores the Tile ID last used for tileset TileSet.
# Used to restore the last used Tile ID for a TileSet when
# the user selects a layer with that TileSet.
var last_used_tile_for_tileset = {}

signal undo_executed

signal object_clicked

func _ready():
	layer_types = get_layer_types()
	
	Global.connect("quit_game_requested", self, "handle_closing_game")
	Global.connect("player_died", self, "enter_edit_mode")
	Global.connect("level_cleared", self, "enter_edit_mode")
	Scoreboard.hide()
	Music.stop_all()
	ResolutionManager.connect("window_resized", self, "window_resized")
	tiles_container.connect("update_selected_tile", self, "update_selected_tile")
	tiles_container.connect("update_selected_object", self, "update_selected_object")
	tiles_container.connect("update_tile_preview_texture", self, "update_tile_preview_texture")
	edit_layer_dialog.connect("layer_parameter_changed", self, "layer_parameter_changed")
	window_resized()
	
	pause_menu.connect("pause_changed", self, "pause_toggled")
	pause_menu.connect("save_and_quit", self, "save_and_quit")
	
	connect("edit_objects_toggled", toggle_edit_button, "update")
	
	Global.connect("object_clicked", self, "object_clicked")
	
	Music.set_editor_music(true)
	
	ResolutionManager.enable_zoom_in = false
	
	#get_tree().paused = true

func _process(delta):
	if !level: return

# =================================================================
# Toggle Edit Mode

func toggle_edit_mode():
	if !level: return
	if edit_mode:
		enter_play_mode()
	else:
		enter_edit_mode()
	update_tilemap_opacity()

func enter_play_mode(play_from_start = Input.is_action_pressed("editor_play_from_start") or edit_objects_enabled):
	if !level: return
	Scoreboard.reset_player_values(false, false)
	
	Global.spawn_position = null if play_from_start else editor_camera.position
	if play_from_start:
		Scoreboard.player_initial_state = 0
		Music.stop_all()

	editor_camera.current = false
	self.selected_layer = null
	tile_functions.selected_tilemap = null
	if !level: return
	create_level_cache()
	if ui_editor: ui_editor.hide()
	level.start_level(true)
	self.edit_mode = false
	get_tree().paused = false
	Music.set_editor_music(false)
	toggle_edit_button.update()

func enter_edit_mode():
	if !level: return
	call_deferred("_deferred_enter_edit_mode")

# We should only enter edit mode when it is safe to do so.
# I.e. don't enter edit mode halfway through the execution of everything
func _deferred_enter_edit_mode():
	get_tree().paused = true
	if level and Global.player:
		if is_instance_valid(level) and is_instance_valid(Global.player):
	
			editor_camera.camera_to_player_position(Global.player, level.is_worldmap)
			Scoreboard.player_initial_state = Global.player.state
			
			if Global.player.get("can_die") != null:
				Global.player.can_die = false
	
	editor_camera.current = true
	self.edit_objects_enabled = false
	self.eyedropper_enabled = false
	
	if !level: return
	
	if cache_level:
		var level_object = cache_level.instance()
		call_deferred("load_level_from_object", level_object)
	
	Scoreboard.hide()
	Scoreboard.level_timer.paused = true
	if ui_editor: ui_editor.show()
	#Music.stop_all()
	#get_tree().paused = false
	self.edit_mode = true
	get_tree().paused = false
	yield(get_tree(), "idle_frame")
	Global.can_pause = true
	Music.set_editor_music(true)
	toggle_edit_button.update()

# ==================================================================================
# Level loading

func load_level_from_path(level_path: String):
	var level_object = load(level_path).instance()
	load_level_from_object(level_object)

func load_level_from_object(level_object: Node2D, free_level_immediately = false):
	unload_current_level()
	
	add_child(level_object)
	level_object.set_owner(self)
	initialise_level(level_object)

func unload_current_level():
	if level:
		level.free()
		#level = null
		#level_objects = null
		#selected_layer = null
		#current_tile_id = -1
		#tile_functions.selected_tilemap = null

func initialise_level(level_object):
	level = level_object
	
	level.play_music(true)
	
	level.connect("music_changed", self, "level_music_changed")
	
	update_layers_panel(self.level_objects)
	
	object_map = null
	for node in self.level_objects:
		#if is_objectmap(node):
		#	object_map = node
		#	break
		
		if node.name == selected_layer_name:
			self.selected_layer = node
	
	update_tilemap_opacity()
	tile_functions.update_level_boundaries(level)
	
	editor_camera.initialise_tux_sprite(level)
	
	emit_signal("level_loaded")

func create_level_cache():
	make_all_tilemaps_opaque()
	
	var level_packedscene = PackedScene.new()
	level_packedscene.pack(level)
	cache_level = level_packedscene
	
	#var dir = Directory.new()
	#dir.make_dir_recursive(cache_level_directory)
	#Global.save_node_to_directory(level, cache_level_path)
	update_tilemap_opacity()

func save_level():
	if !level: return
	call_deferred("_deferred_save_level")

func _deferred_save_level():
	if !level: return
	
	if !edit_mode: _deferred_enter_edit_mode()
	
	make_all_tilemaps_opaque()
	var level_directory = UserLevels.current_level
	var save_status = Global.save_node_to_directory(level, level_directory)
	update_tilemap_opacity()
	
	if save_status == OK:
		unsaved_changes = false
		
		play_sound("Save")

func save_and_quit():
	save_level()
	Global.goto_level_editor_world_menu(UserLevels.current_world)

# Fills the layers panel with all layers in the current level
func update_layers_panel(level_objects):
	if !layers_container: return
	
	for layer in layers_container.get_children():
		layers_container.remove_child(layer)
		layer.free()
	
	var sorted_layers = level_objects
	sorted_layers.sort_custom(self, "sort_layers")
	
	for node in sorted_layers:
		#if is_objectmap(node): continue
		var button = layer_button_scene.instance()
		layers_container.add_child(button)
		button.layer_name = node.name
		button.layer_object = node
		button.connect("layer_button_pressed", self, "layer_button_pressed")
		button.connect("edit_layer", self, "edit_layer")
		button.connect("delete_layer", self, "delete_layer")
	
	update_selected_layer(selected_layer)

# Custom sorting algorithm for Nodes.
# If both nodes have a Z index, sort them by lowest Z index.
# Otherwise, sort the nodes by name.
func sort_layers(a, b):
	var a_priority = a.get("z_index")
	var b_priority = b.get("z_index")
	
	if _is_layer_sorted_last(a): a_priority = 99999
	if _is_layer_sorted_last(b): b_priority = 99999
	
	if a_priority != null and b_priority != null:
		if a.z_index == b.z_index: return a.name < b.name
		else: return a.z_index < b.z_index
	else:
		return a.name < b.name

func _is_layer_sorted_last(layer_node : Node):
	return is_object_container(layer_node)

# ====================================================================================
# Editor UI

func _on_EditToggle_pressed():
	toggle_edit_mode()

# The Editor UI shrinks on smaller displays
func window_resized():
	# The Editor UI gets smaller when the screen resolution is lower than the target resolution
	var scale = min(ResolutionManager.window_size.x / ui_scale_min_resolution.x, ResolutionManager.window_size.y / ui_scale_min_resolution.y)
	scale = min(scale, 1)
	scale /= ResolutionManager.screen_shrink # Make editor UI immune to magnification
	set_ui_scale(scale)

func set_ui_scale(scale):
	ui_scale.rect_scale = Vector2.ONE * scale
	
	ui_scale.anchor_bottom = 1 / scale
	ui_scale.anchor_right = 1 / scale

func layer_button_pressed(button_node, layer_object):
	
	# If we have edit layers mode enabled
	if edit_objects_enabled:
		if layer_object:
			if is_instance_valid(layer_object):
				self.edit_objects_enabled = false
				edit_layer(layer_object)
		return
	
	var old_selected_layer = selected_layer
	
	self.selected_layer = layer_object
	
	if selected_layer:
		if is_instance_valid(selected_layer):
			# Make Flip Tiles auto-enable when selecting object maps,
			# and auto-disable when selecting tilemaps
			self.flip_tiles_enabled = is_objectmap(selected_layer)
	
	# Reset the currently selected tile/object when
	# selecting a layer with a different TileSet than the current one
	if selected_layer and old_selected_layer:
		if is_instance_valid(selected_layer) and is_instance_valid(old_selected_layer):
			if !is_tilemap(selected_layer) or selected_layer.get("tile_set") != old_selected_layer.get("tile_set"):
				self.current_object_resource = null
				self.current_tile_id = -1
				
				var tileset = selected_layer.get("tile_set")
				# When selecting TileMap layers,
				# the editor will restore whatever tile you had last selected
				# for the TileSet.
				if last_used_tile_for_tileset.has(tileset):
					
					var tile = last_used_tile_for_tileset[tileset]
					self.current_tile_id = tile
	

func update_selected_layer(new_value):
	var layer_exists = false
	if new_value: layer_exists = is_instance_valid(new_value)
	
	if layer_exists:
		
		# Select Layer Sound
		if new_value != null:
			if selected_layer_name != new_value.name:
				play_sound("SelectLayer")
		
		selected_layer = new_value
		selected_layer_name = selected_layer.name
		
		for button in layers_container.get_children():
			button.set_disabled(button.layer_object == selected_layer)
		
		update_tilemap_opacity()
		
		object_functions.object_container = null
		tile_functions.selected_tilemap = null
		
		if is_tilemap(selected_layer):
			object_functions.object_container = null
			tile_functions.selected_tilemap = selected_layer
			tiles_container.show_tiles_from_tilemap(selected_layer)
			
		elif is_object_container(selected_layer):
			object_functions.object_container = selected_layer
			tile_functions.selected_tilemap = null
			tiles_container.show_object_scenes_in_folder(self.object_scenes_folder)
		
		else:
			tiles_container.empty_tiles()
	
	else:
		object_functions.object_container = null
		tile_functions.selected_tilemap = null
		tiles_container.empty_tiles()
		
		for button in layers_container.get_children():
			button.set_disabled(false)

func update_tilemap_opacity():
	var selected_layer_exists = false
	if selected_layer:
		if is_instance_valid(selected_layer):
			selected_layer_exists = true
	
	if selected_layer_exists and edit_mode:
		if (is_tilemap(selected_layer) or is_object_container(selected_layer)):
			make_non_selected_tilemaps_transparent()
		else:
			make_all_tilemaps_opaque()
	else:
		make_all_tilemaps_opaque()

func make_non_selected_tilemaps_transparent():
	for child in self.level_objects:
		if !is_instance_valid(child): continue
		if is_tilemap(child) or is_objectmap(child):
			if selected_layer != child:
				child.modulate.a = unselected_tilemap_opacity
			else: child.modulate.a = 1
		elif is_object_container(child): child.modulate.a = 1

func make_all_tilemaps_opaque():
	for child in self.level_objects:
		if !is_instance_valid(child): continue
		if is_tilemap(child) or is_object_container(child):
			child.modulate.a = 1

func is_tilemap(node):
	return node is TileMap# and not node.is_in_group("objectmaps")

func is_object_container(node):
	return node.is_in_group("object_container")

func is_objectmap(node):
	return node is TileMap and node.is_in_group("objectmaps")

func update_selected_tile(selected_tile_id : int):
	self.eraser_enabled = false
	emit_signal("eraser_toggled", false)
	
	current_tile_id = selected_tile_id
	current_object_resource = null
	
	# Store the currently selected tile for this TileSet
	# as its last used tile. If we select a TileMap layer with
	# a different tileset, then go back to the layer with this TileSet,
	# the editor will restore whatever tile you had last selected.
	if selected_tile_id != -1:
		if selected_layer:
			if is_instance_valid(selected_layer):
				var tileset = selected_layer.get("tile_set")
				if tileset:
					last_used_tile_for_tileset[tileset] = current_tile_id
		
		update_tile_preview_texture(null, null)
	
	play_sound("SelectTile")

func update_selected_object(selected_object_resource : Resource):
	self.eraser_enabled = false
	emit_signal("eraser_toggled", false)
	
	current_object_resource = selected_object_resource
	current_tile_id = -1
	
	if selected_object_resource == null:
		update_tile_preview_texture(null, null)
	
	play_sound("SelectTile")

func _on_Eraser_toggled(button_pressed):
	eraser_enabled = button_pressed
	emit_signal("eraser_toggled", button_pressed)

func _on_RectSelect_toggled(button_pressed):
	rect_select_enabled = button_pressed
	emit_signal("rect_select_toggled", button_pressed)

func _on_EyeDropper_toggled(button_pressed):
	eyedropper_enabled = button_pressed
	emit_signal("eyedropper_toggled", button_pressed)
	
	if button_pressed:
		self.rect_select_enabled = false
		emit_signal("rect_select_toggled", false)
		self.eraser_enabled = false
		emit_signal("eraser_toggled", false)

func _on_FlipTiles_toggled(button_pressed):
	flip_tiles_enabled = button_pressed
	emit_signal("flip_tiles_toggled", button_pressed)

func update_rect_select_enabled(new_value):
	rect_select_enabled = new_value
	button_rect_select.pressed = new_value
	emit_signal("rect_select_toggled", new_value)

func update_eraser_enabled(new_value):
	eraser_enabled = new_value
	button_eraser.pressed = new_value
	emit_signal("eraser_toggled", new_value)

func update_eyedropper_enabled(new_value):
	eyedropper_enabled = new_value
	button_eyedropper.pressed = new_value
	emit_signal("eyedropper_toggled", new_value)

func update_flip_tiles_enabled(new_value):
	flip_tiles_enabled = new_value
	button_flip_tiles.pressed = new_value
	emit_signal("flip_tiles_toggled", new_value)

func add_layer(layer_name : String, layer_type : String):
	if !level: return
	if !is_instance_valid(level): return
	
	var layer_node_path = editor_layers_directory + layer_type + ".tscn"
	
	var file = File.new()
	if file.file_exists(layer_node_path):
		var layer_node = load(layer_node_path).instance()
		layer_node.set_name(layer_name)
		
		if layer_node.get("is_in_worldmap") != null:
			layer_node.set("is_in_worldmap", level.is_worldmap)
		
		level.add_child(layer_node)
		layer_node.set_owner(level)
		update_layers_panel(self.level_objects)
		update_selected_layer(layer_node)
		
		play_sound("AddLayer")
		
	else:
		push_error("ERROR ADDING LAYER: Layer scene for layer '" + layer_type + "' not found!")

# Returns a string array of all the names of scenes within res://scenes/layers/
func get_layer_types():
	var types = []
	
	var f = File.new()
	var filename_getter = RegEx.new()
	filename_getter.compile("(.+).tscn")
	
	for file in Global.list_files_in_directory(editor_layers_directory):
		var file_is_layer = filename_getter.search(file)
		
		if file_is_layer:
			var file_name = file_is_layer.get_strings()[1]
			types.append(file_name)
	
	return types

# Returns an array of all layer nodes inside the level.
func _get_level_objects(object_node = level, objects := []):
	
	for child in object_node.get_children():
		
		# If the object is a shader container, just get all the children of
		# the shader and ignore the shader node itself.
		if child.name == "Shader":
			var child_objects = _get_level_objects(child)
			objects.append_array(child_objects)
		else:
			objects.append(child)
	
	#for child in level_objects:
	#	print(child.name)
	
	return objects

func edit_layer(layer_object : Node, object_is_layer = true):
	if edit_layer_dialog.visible: return
	add_undo_state()
	edit_layer_dialog.appear(layer_object, !object_is_layer)

func edit_object(object : Node):
	if object.get("editor_params") == null: return
	edit_layer(object, false)

func delete_layer(layer_object : Node):
	add_undo_state()
	call_deferred("_deferred_delete_layer", layer_object)

func _deferred_delete_layer(layer_object : Node):
	if selected_layer == layer_object:
		self.selected_layer = null
	layer_object.free()
	update_layers_panel(self.level_objects)
	play_sound("DeleteLayer")

func layer_parameter_changed():
	update_layers_panel(self.level_objects)
	add_undo_state()

func _update_current_tile_id(new_value):
	current_tile_id = new_value
	tiles_container.update_selected_tile(current_tile_id)

func _update_current_object_resource(new_value):
	current_object_resource = new_value
	tiles_container.update_selected_object(current_object_resource)

func _on_SaveButton_pressed():
	save_level()

func _on_UndoButton_pressed():
	undo()

func undo():
	if !level: return
	
	if undo_stack.empty(): return
	
	var last_state = undo_stack.back()
	
	var level_object = last_state.instance()
	
	call_deferred("load_level_from_object", level_object)
	
	undo_stack.erase(last_state)
	button_undo.disabled = undo_stack.empty()
	
	emit_signal("undo_executed")
	
	unsaved_changes = true
	
	play_sound("Undo")
	
	#print("Remove undo state")
	#print(undo_stack)

func _on_LevelProperties_pressed():
	level_properties_dialog()

func level_properties_dialog():
	add_undo_state()
	level_properties_dialog.popup_centered_ratio(0.8)
	play_sound("LevelProperties")

func clear_undo_states():
	undo_stack = []

func add_undo_state():
	var level_packedscene = PackedScene.new()
	level_packedscene.pack(level)
	undo_stack.append(level_packedscene)
	
	button_undo.disabled = false
	
	unsaved_changes = true
	
	#print("Add undo state")
	#print(undo_stack)

func pause_toggled(paused : bool):
	is_paused = paused
	if ui_editor: ui_editor.visible = !is_paused and edit_mode
	
	tile_functions.stop_placing_tiles()

func object_clicked(object : Node, click_type : int):
	if !edit_mode: return
	if self.mouse_over_ui: return
	if !object: return
	if !is_instance_valid(object): return
	
	var can_delete_object = object.get_owner() != self
	
	var can_edit_objects = false
	if selected_layer:
		if is_instance_valid(selected_layer):
			can_edit_objects = is_object_container(selected_layer)
	
	object_functions.can_place_objects = false
	
	if edit_objects_enabled:
		edit_object(object)
		self.edit_objects_enabled = false
		return
	
	var eyedropping = eyedropper_enabled or click_type == BUTTON_MIDDLE
	
	if eyedropping and can_edit_objects:
		var object_resource = load(object.filename)
		if object_resource:
			self.current_object_resource = object_resource
			self.eyedropper_enabled = false
			play_sound("Eyedrop")
			return
	
	elif click_type == BUTTON_RIGHT:
		if object.get("editor_params") == null:
			if can_delete_object: object_functions.delete_object(object)
		else: edit_object(object)
	
	elif eraser_enabled and can_delete_object:
		object_functions.delete_object(object)
	
	elif click_type == BUTTON_LEFT:
		object_functions.grab_object(object)

func _get_can_place_tiles():
	return !editor_camera.dragging_camera and !object_functions.dragged_object and !is_paused and edit_mode and !edit_objects_enabled and !MobileControls.joystick_active

func _get_object_scenes_folder():
	if !level: return null
	if !is_instance_valid(level): return null
	
	return object_scene_folder_for_worldmaps if level.is_worldmap else object_scene_folder_for_levels


func _input(event):
	if is_paused: return
	
	# Toggle play/edit mode with ENTER
	
	if Input.is_action_just_pressed("editor_test_level"):
		if !Global.is_popup_visible():
			toggle_edit_mode()
	
	if !edit_mode: return
	
	# ========================================================================
	# Editor-specific keyboard shortcuts
	
	# Keyboard shortcut support for UNDO and SAVE actions.
	if Input.is_key_pressed(KEY_CONTROL):
		if Input.is_key_pressed(KEY_S):
			save_level()
		elif Input.is_key_pressed(KEY_Z):
			undo()
		elif Input.is_key_pressed(KEY_P):
			level_properties_dialog()
	
	# Make the editor buttons activate when user is holding down shortcuts
	if Input.is_action_just_pressed("editor_erase"):
		self.eraser_enabled = true
	
	if Input.is_action_just_released("editor_erase"):
		self.eraser_enabled = false
	
	if Input.is_action_just_pressed("editor_rect_select"):
		self.rect_select_enabled = true
	
	if Input.is_action_just_released("editor_rect_select"):
		self.rect_select_enabled = false
	
	if Input.is_action_just_pressed("editor_eyedrop_tool"):
		self.eyedropper_enabled = true
	
	if Input.is_action_just_released("editor_eyedrop_tool"):
		self.eyedropper_enabled = false
	
	if Input.is_action_just_pressed("editor_flip_tiles"):
		self.flip_tiles_enabled = !flip_tiles_enabled
	
	if Input.is_action_just_pressed("editor_eraser_toggle"):
		self.eraser_enabled = !eraser_enabled

func play_sound(sound_effect : String):
	sfx.play(sound_effect)

# This function runs when the user attempts to quit the game while
# the editor is open.
func handle_closing_game():
	if quit_without_saving_dialog.visible: return
	
	if !unsaved_changes:
		get_tree().quit()
	else:
		quit_without_saving_dialog.popup_centered_ratio()
	pass

func _on_UnsavedChangesDialog_about_to_show():
	pause_menu.paused = false
	if !edit_mode:
		yield(call("_deferred_enter_edit_mode"), "completed")
	pause_toggled(true)

func _on_UnsavedChangesDialog_popup_hide():
	pause_toggled(false)

func _on_SaveAndExit_pressed():
	save_level()
	get_tree().quit()

func _on_ExitWithoutSaving_pressed():
	get_tree().quit()

func _on_CancelExitProgram_pressed():
	quit_without_saving_dialog.hide()

func level_music_changed(new_music):
	if level:
		if is_instance_valid(level):
			level.play_music(true)

func _on_EditLayerDialog_about_to_show():
	play_sound("EditLayer")

func update_tile_preview_texture(new_texture, region_rect):
	var preview_sprites = [tile_functions.tile_preview, object_functions.tile_preview]
	
	for sprite in preview_sprites:
		sprite.region_enabled = region_rect != null
		if region_rect: sprite.region_rect = region_rect
		sprite.texture = new_texture

func _on_LevelPropertiesDialog_popup_hide():
	play_sound("LevelPropertiesClose")
	play_sound("LevelPropertiesChanged")

func _on_AddLayerDialog_about_to_show():
	play_sound("AddLayerDialog")

func _update_edit_mode(new_value):
	edit_mode = new_value
	ResolutionManager.enable_zoom_in = !edit_mode

func _on_EditObject_toggled(button_pressed):
	self.edit_objects_enabled = button_pressed

func update_edit_objects_enabled(new_value):
	edit_objects_enabled = new_value
	button_edit_objects.pressed = new_value
	emit_signal("edit_objects_toggled")

func _get_mouse_over_ui():
	if is_paused: return true
	if edit_layer_dialog.visible: return true
	if MobileControls.mouse_over_ui: return true
	
	return is_mouse_hovering_over_node(ui_scale)

# Recursive function which determines if the mouse is
# hovering over a control node, or any visible children
# of the control node.
func is_mouse_hovering_over_node(node : Control):
	for child in node.get_children():
		if !(child is Control): continue
		if !child.visible: continue
		
		if is_mouse_hovering_over_node(child) == true:
			return true
	
	if node is Control:
		if node.mouse_filter == MOUSE_FILTER_STOP:
			var hitbox = Rect2(Vector2.ZERO, node.rect_size)
			if hitbox.has_point(node.get_local_mouse_position()):
				return true
	
	return false
