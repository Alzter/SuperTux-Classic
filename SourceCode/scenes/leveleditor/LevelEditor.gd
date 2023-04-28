extends Control

export var level_to_load = "res://scenes/levels/world1/level1.tscn"

export var cache_level_directory = "user://leveleditor/"
export var cache_level_filename = "cache.tscn"

onready var tile_functions = $TileFunctions
onready var editor_camera = $EditorCamera

onready var ui_scale = $UI/Scale
onready var ui_editor = $UI/Scale/EditorUI
onready var layers_container = $UI/Scale/EditorUI/LayersPanelOffset/LayersPanel/ScrollContainer/LayersContainer

export var layer_button_scene : PackedScene

onready var cache_level_path = cache_level_directory + cache_level_filename

var level = null
var level_objects = null
var object_map = null

var selected_object = null setget update_selected_object
var selected_object_name = ""

var edit_mode = true

var can_place_tiles = true

func _ready():
	Scoreboard.hide()
	Music.stop_all()
	ResolutionManager.connect("window_resized", self, "window_resized")
	window_resized()
	
	editor_camera.connect("set_camera_drag", self, "set_camera_drag")
	
	load_level_from_path(level_to_load)

func _process(delta):
	if !level: return

# =================================================================
# Toggle Edit Mode

func toggle_edit_mode():
	if edit_mode:
		enter_play_mode()
	else:
		enter_edit_mode()
	edit_mode = !edit_mode
	update_tilemap_opacity()

func enter_play_mode():
	editor_camera.current = false
	self.selected_object = null
	if !level: return
	create_level_cache()
	if ui_editor: ui_editor.hide()
	level.start_level(false)

func enter_edit_mode():
	if Global.player:
		editor_camera.camera_to_player_position(Global.player)
	editor_camera.current = true
	
	if !level: return
	load_level_from_path(cache_level_path)
	Scoreboard.hide()
	if ui_editor: ui_editor.show()
	Music.stop_all()

# ==================================================================================
# Level loading

func load_level_from_path(level_path: String):
	var level_object = load(level_path).instance()
	load_level_from_object(level_object)

func load_level_from_object(level_object: Node2D):
	if level:
		level.queue_free()
		yield(level, "tree_exited")
	
	add_child(level_object)
	level_object.set_owner(self)
	initialise_level(level_object)

func initialise_level(level_object):
	level = level_object
	level_objects = level_object.get_children()
	
	update_layers_panel(level_objects)
	
	object_map = null
	for node in level_objects:
		if is_objectmap(node):
			object_map = node
			break
		
		if node.name == selected_object_name:
			self.selected_object = node
	
	update_tilemap_opacity()
	tile_functions.update_level_boundaries(level)

func create_level_cache():
	make_all_tilemaps_opaque()
	var dir = Directory.new()
	dir.make_dir_recursive(cache_level_directory)
	Global.save_node_to_directory(level, cache_level_path)
	update_tilemap_opacity()

# Fills the layers panel with all layers in the current level
func update_layers_panel(level_objects):
	if !layers_container: return
	
	for layer in layers_container.get_children():
		layers_container.remove_child(layer)
		layer.free()
	
	for node in level_objects:
		if is_objectmap(node): continue
		var button = layer_button_scene.instance()
		layers_container.add_child(button)
		button.text = node.name
		button.layer_object = node
		button.connect("layer_button_pressed", self, "layer_button_pressed")

# ====================================================================================
# Editor UI

func _on_EditToggle_pressed():
	toggle_edit_mode()

# The Editor UI shrinks on smaller displays
func window_resized():
	# The Editor UI gets smaller when the screen resolution is lower than this
	var target_resolution = Vector2(1000, 500)
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
	else: tile_functions.selected_tilemap = null

func update_tilemap_opacity():
	if selected_object and edit_mode:
		if is_tilemap(selected_object):
			make_non_selected_tilemaps_transparent()
		else:
			make_all_tilemaps_opaque()
	else:
		make_all_tilemaps_opaque()

func make_non_selected_tilemaps_transparent():
	for child in level_objects:
		if !is_instance_valid(child): continue
		if is_tilemap(child):
			if selected_object != child:
				child.modulate.a = 0.25
			else: child.modulate.a = 1

func make_all_tilemaps_opaque():
	for child in level_objects:
		if !is_instance_valid(child): continue
		if is_tilemap(child):
			child.modulate.a = 1

func is_tilemap(node):
	return node is TileMap and not node.is_in_group("objectmaps")

func is_objectmap(node):
	return node is TileMap and node.is_in_group("objectmaps")

func set_camera_drag(is_dragging = true):
	can_place_tiles = !is_dragging
