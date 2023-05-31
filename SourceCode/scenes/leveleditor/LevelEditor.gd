extends Control

#export var level_to_load = "res://scenes/levels/world1/level1.tscn"

# The Editor UI gets smaller when the screen resolution is lower than this
export var target_resolution = Vector2(1000, 500)

var cache_level = null

export var unselected_tilemap_opacity = 0.3

export var editor_layers_directory = "res://scenes/layers/"

onready var tile_functions = $TileFunctions
onready var editor_camera = $EditorCamera

onready var ui_scale = $UI/Scale
onready var ui_editor = $UI/Scale/EditorUI
onready var tiles_container = $UI/Scale/EditorUI/TilesPanelOffset/TilesPanel/ScrollContainer/TilesContainer
onready var layers_container = $UI/Scale/EditorUI/LayersPanelOffset/LayersPanel/ScrollContainer/LayersContainer

var rect_select_enabled = false setget update_rect_select_enabled
var eraser_enabled = false setget update_eraser_enabled
var eyedropper_enabled = false setget update_eyedropper_enabled

onready var button_rect_select = $UI/Scale/EditorUI/TilesPanelOffset/TilesPanel/PlacementOptions/RectSelect
onready var button_eraser = $UI/Scale/EditorUI/TilesPanelOffset/TilesPanel/PlacementOptions/Eraser
onready var button_eyedropper = $UI/Scale/EditorUI/TilesPanelOffset/TilesPanel/PlacementOptions/EyeDropper
onready var button_undo = $UI/Scale/EditorUI/Buttons/UndoButton

onready var button_level_properties = $UI/Scale/EditorUI/Buttons/LevelProperties
onready var level_properties_panel = $UI/Scale/EditorUI/LevelPropertiesOffset/LevelPropertiesPanel

export var layer_button_scene : PackedScene

#onready var cache_level_path = cache_level_directory + cache_level_filename

onready var edit_layer_dialog = $UI/Scale/EditorUI/EditLayerDialog
onready var pause_menu = $PauseMenu

signal level_loaded

signal eraser_toggled
signal rect_select_toggled
signal eyedropper_toggled

var level = null
var level_objects = null setget , _get_level_objects
var object_map = null

var selected_object = null setget update_selected_object
var selected_object_name = ""
var current_tile_id = -1 setget _update_current_tile_id # The ID of the tile the user is currently using

var edit_mode = true

var can_place_tiles = true

var mouse_over_ui = false

var layer_types = []

var undo_stack = []

signal undo_executed

func _ready():
	layer_types = get_layer_types()
	
	Global.connect("player_died", self, "enter_edit_mode")
	Global.connect("level_cleared", self, "enter_edit_mode")
	Scoreboard.hide()
	Music.stop_all()
	ResolutionManager.connect("window_resized", self, "window_resized")
	tiles_container.connect("update_selected_tile", self, "update_selected_tile")
	edit_layer_dialog.connect("layer_parameter_changed", self, "layer_parameter_changed")
	window_resized()
	
	pause_menu.connect("pause_changed", self, "pause_toggled")
	pause_menu.connect("save_and_quit", self, "save_and_quit")
	
	editor_camera.connect("set_camera_drag", self, "set_camera_drag")
	
	connect("level_loaded", level_properties_panel, "appear")
	
	Global.connect("object_right_clicked", self, "object_right_clicked")
	
	get_tree().paused = true

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

func enter_play_mode():
	if !level: return
	Scoreboard.reset_player_values(false, false)
	Global.spawn_position = editor_camera.position
	editor_camera.current = false
	self.selected_object = null
	if !level: return
	create_level_cache()
	if ui_editor: ui_editor.hide()
	level.start_level(true)
	edit_mode = false
	get_tree().paused = false

func enter_edit_mode():
	if !level: return
	call_deferred("_deferred_enter_edit_mode")

# We should only enter edit mode when it is safe to do so.
# I.e. don't enter edit mode halfway through the execution of everything
func _deferred_enter_edit_mode():
	get_tree().paused = true
	if level and Global.player:
		editor_camera.camera_to_player_position(Global.player, level.is_worldmap)
		Scoreboard.player_initial_state = Global.player.state
	
	editor_camera.current = true
	
	if !level: return
	
	if cache_level:
		var level_object = cache_level.instance()
		call_deferred("load_level_from_object", level_object)
	
	Scoreboard.hide()
	Scoreboard.level_timer.paused = true
	if ui_editor: ui_editor.show()
	Music.stop_all()
	#get_tree().paused = false
	edit_mode = true
	Global.can_pause = true

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
		#selected_object = null
		#current_tile_id = -1
		#tile_functions.selected_tilemap = null

func initialise_level(level_object):
	level = level_object
	
	update_layers_panel(self.level_objects)
	
	object_map = null
	for node in self.level_objects:
		#if is_objectmap(node):
		#	object_map = node
		#	break
		
		if node.name == selected_object_name:
			self.selected_object = node
	
	update_tilemap_opacity()
	tile_functions.update_level_boundaries(level)
	
	editor_camera.initialise_tux_sprite(level.is_worldmap)
	
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
	call_deferred("_deferred_save_level")

func _deferred_save_level():
	if !edit_mode: _deferred_enter_edit_mode()
	
	make_all_tilemaps_opaque()
	var level_directory = UserLevels.current_level
	Global.save_node_to_directory(level, level_directory)
	update_tilemap_opacity()

func save_and_quit():
	save_level()
	Global.goto_level_editor_main_menu()

# Fills the layers panel with all layers in the current level
func update_layers_panel(level_objects):
	if !layers_container: return
	
	for layer in layers_container.get_children():
		layers_container.remove_child(layer)
		layer.free()
	
	for node in level_objects:
		#if is_objectmap(node): continue
		var button = layer_button_scene.instance()
		layers_container.add_child(button)
		button.text = node.name
		button.layer_object = node
		button.connect("layer_button_pressed", self, "layer_button_pressed")
		button.connect("edit_layer", self, "edit_layer")
		button.connect("delete_layer", self, "delete_layer")

# ====================================================================================
# Editor UI

func _on_EditToggle_pressed():
	toggle_edit_mode()

# The Editor UI shrinks on smaller displays
func window_resized():
	# The Editor UI gets smaller when the screen resolution is lower than the target resolution
	var scale = min(ResolutionManager.window_size.x / target_resolution.x, ResolutionManager.window_size.y / target_resolution.y)
	scale = min(scale, 1)
	scale /= ResolutionManager.screen_shrink # Make editor UI immune to magnification
	set_ui_scale(scale)

func set_ui_scale(scale):
	ui_scale.rect_scale = Vector2.ONE * scale
	ui_scale.anchor_bottom = 1 / scale
	ui_scale.anchor_right = 1 / scale

func layer_button_pressed(button_node, layer_object):
	self.selected_object = layer_object

func update_selected_object(new_value):
	selected_object = new_value
	if selected_object:
		selected_object_name = selected_object.name
	
	for button in layers_container.get_children():
		button.disabled = button.layer_object == selected_object
	
	update_tilemap_opacity()
	
	if is_tilemap(selected_object):
		tile_functions.selected_tilemap = selected_object
		tiles_container.show_tiles_from_tilemap(selected_object)
	else:
		tile_functions.selected_tilemap = null
		tiles_container.empty_tiles()

func update_tilemap_opacity():
	if selected_object and edit_mode:
		if is_tilemap(selected_object) and !is_objectmap(selected_object):
			make_non_selected_tilemaps_transparent()
		else:
			make_all_tilemaps_opaque()
	else:
		make_all_tilemaps_opaque()

func make_non_selected_tilemaps_transparent():
	for child in self.level_objects:
		if !is_instance_valid(child): continue
		if is_tilemap(child):
			if selected_object != child:
				child.modulate.a = unselected_tilemap_opacity
			else: child.modulate.a = 1

func make_all_tilemaps_opaque():
	for child in self.level_objects:
		if !is_instance_valid(child): continue
		if is_tilemap(child):
			child.modulate.a = 1

func is_tilemap(node):
	return node is TileMap# and not node.is_in_group("objectmaps")

func is_objectmap(node):
	return node is TileMap and node.is_in_group("objectmaps")

func set_camera_drag(is_dragging = true):
	can_place_tiles = !is_dragging

func update_selected_tile(selected_tile_id : int):
	current_tile_id = selected_tile_id

func _on_Eraser_toggled(button_pressed):
	eraser_enabled = button_pressed
	emit_signal("eraser_toggled", button_pressed)

func _on_RectSelect_toggled(button_pressed):
	rect_select_enabled = button_pressed
	emit_signal("rect_select_toggled", button_pressed)

func _on_EyeDropper_toggled(button_pressed):
	eyedropper_enabled = button_pressed
	emit_signal("eyedropper_toggled", button_pressed)

func update_rect_select_enabled(new_value):
	button_rect_select.pressed = new_value

func update_eraser_enabled(new_value):
	button_eraser.pressed = new_value

func update_eyedropper_enabled(new_value):
	button_eyedropper.pressed = new_value

# When User hovers over the UI
func _on_MouseDetector_mouse_entered():
	mouse_over_ui = false

# When user stops hovering over the UI
func _on_MouseDetector_mouse_exited():
	mouse_over_ui = true

func add_layer(layer_name : String, layer_type : String):
	var layer_node_path = editor_layers_directory + layer_type + ".tscn"
	
	var file = File.new()
	if file.file_exists(layer_node_path):
		var layer_node = load(layer_node_path).instance()
		layer_node.set_name(layer_name)
		level.add_child(layer_node)
		layer_node.set_owner(level)
		update_layers_panel(self.level_objects)
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
	
	return objects

func edit_layer(layer_object : Node):
	add_undo_state()
	edit_layer_dialog.appear(layer_object)

func delete_layer(layer_object : Node):
	add_undo_state()
	call_deferred("_deferred_delete_layer", layer_object)

func _deferred_delete_layer(layer_object : Node):
	if selected_object == layer_object:
		self.selected_object = null
	layer_object.free()
	update_layers_panel(self.level_objects)

func layer_parameter_changed():
	update_layers_panel(self.level_objects)
	add_undo_state()

func _update_current_tile_id(new_value):
	current_tile_id = new_value
	tiles_container.update_selected_tile(current_tile_id)

func _on_SaveButton_pressed():
	save_level()

func _on_UndoButton_pressed():
	if undo_stack.empty(): return
	
	var last_state = undo_stack.back()
	
	var level_object = last_state.instance()
	
	call_deferred("load_level_from_object", level_object)
	
	undo_stack.erase(last_state)
	button_undo.disabled = undo_stack.empty()
	
	emit_signal("undo_executed")
	
	#print("Remove undo state")
	#print(undo_stack)

func clear_undo_states():
	undo_stack = []

func add_undo_state():
	var level_packedscene = PackedScene.new()
	level_packedscene.pack(level)
	undo_stack.append(level_packedscene)
	
	button_undo.disabled = false
	
	#print("Add undo state")
	#print(undo_stack)

func pause_toggled(is_paused : bool):
	if ui_editor: ui_editor.visible = !is_paused and edit_mode

func object_right_clicked(object : Node):
	if !edit_mode: return
	if edit_layer_dialog.visible: return
	if !object: return
	
	print(object)
	add_undo_state()
	edit_layer_dialog.appear(object)
