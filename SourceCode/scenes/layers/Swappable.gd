extends Node2D

export var editor_params = ["type"]

onready var scene_node = get_node_or_null("Default")
export var name_of_default_node = "SnowBackground"

onready var current_scene = name_of_default_node
var swappable_scenes = []
var folder_of_swappable_scenes = null

func _ready():
	if !is_in_group("swappables"):
		add_to_group("swappables", true)
	
	_get_swappable_scenes()

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

func swap_to_scene(scene_name : String):
	call_deferred("_deferred_swap_to_scene", scene_name)

func _deferred_swap_to_scene(scene_name : String):
	if !swappable_scenes.has(scene_name): return
	
	var scene_file = folder_of_swappable_scenes + scene_name + ".tscn"
	scene_node.free()
	scene_node = null
	
	var new_scene = load(scene_file).instance()
	add_child(new_scene)
	new_scene.set_owner(self)
	
	scene_node = new_scene
