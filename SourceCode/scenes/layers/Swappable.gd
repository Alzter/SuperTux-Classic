extends Node2D

export var editor_params = ["type"]

export var child_editor_params = {
	#"var1" : 10,
	#"var2" : true,
	#"var3" : "String",
}

onready var scene_node = null if get_child_count() == 0 else get_child(0)
export var current_scene = "Snow" setget _update_current_scene

var swappable_scenes = []
var folder_of_swappable_scenes = null

onready var type = [] setget _set_type, _get_type

func _ready():
	if !is_in_group("swappables"):
		add_to_group("swappables", true)
	
	_get_swappable_scenes()
	
	if !scene_node:
		swap_to_scene(current_scene)

func _get_swappable_scenes():
	var folder_name = filename.trim_suffix(".tscn") + "/"
	
	if !folder_name: return
	
	var dir = Directory.new()
	
	if dir.dir_exists(folder_name):
		folder_of_swappable_scenes = folder_name
		var potential_scenes = Global.list_files_in_directory(folder_name)
		
		for scene in potential_scenes:
			if scene.ends_with(".tscn"):
				swappable_scenes.append(scene.trim_suffix(".tscn"))

func _update_current_scene(new_value):
	if new_value == current_scene: return
	
	current_scene = new_value
	swap_to_scene(new_value)

func swap_to_scene(scene_name : String):
	call_deferred("_deferred_swap_to_scene", scene_name)

func _deferred_swap_to_scene(scene_name : String):
	if !swappable_scenes.has(scene_name): return
	
	if !child_editor_params.empty():
		_load_child_editor_parameters()
	
	var scene_file = folder_of_swappable_scenes + scene_name + ".tscn"
	if scene_node: scene_node.free()
	scene_node = null
	
	var new_scene = load(scene_file).instance()
	add_child(new_scene)
	new_scene.set_owner(self)
	
	scene_node = new_scene
	
	if child_editor_params.empty():
		_load_child_editor_parameters()
	else: _set_child_editor_parameters()

# Empties the child editor parameters dictionary,
# then sets it to all editor parameters of the child scene.
func _load_child_editor_parameters():
	if !scene_node: return
	if !is_instance_valid(scene_node): return
	
	var params = scene_node.get("editor_params")
	if !params: return
	
	child_editor_params = {}
	
	for key in params:
		var value = scene_node.get(key)
		if value == null: continue
		
		child_editor_params[key] = value
	
	_add_child_editor_parameters_into_list()

# Adds the child editor parameters into the main editor parameters list.
# This allows them to be modified by the user.
func _add_child_editor_parameters_into_list():
	# Add the child editor parameters into the main editor parameters
	# if they aren't already there yet.

	if !child_editor_params.empty():
		
		var first_item = child_editor_params.keys().front()
		
		if !editor_params.has(first_item):
			editor_params.append_array(child_editor_params.keys())

# Sets all editor parameters of the child scene to the values
# of the child editor parameter dictionary.
func _set_child_editor_parameters():
	if !scene_node: return
	if !is_instance_valid(scene_node): return
	
	for key in child_editor_params.keys():
		var value = child_editor_params.get(key)
		
		if scene_node.get(key) != null:
			scene_node.set(key, value)

func _get_child_editor_param(param_name : String):
	if !scene_node: return
	if !is_instance_valid(scene_node): return
	
	return scene_node.get(param_name)

func _set_child_editor_param(param_name : String, value):
	if !scene_node: return
	if !is_instance_valid(scene_node): return
	
	scene_node.set(param_name, value)
	child_editor_params[param_name] = value

func _set_type(new_value):
	if new_value is Array:
		if new_value.size() == 2:
			self.current_scene = new_value[0]
			self.swappable_scenes = new_value[1]

func _get_type():
	return [current_scene, swappable_scenes]

func get(variable_name : String):
	if child_editor_params.has(variable_name):
		return _get_child_editor_param(variable_name)
	
	return .get(variable_name)

func set(variable_name : String, value):
	if child_editor_params.has(variable_name):
		_set_child_editor_param(variable_name, value)
		return
	
	.set(variable_name, value)
