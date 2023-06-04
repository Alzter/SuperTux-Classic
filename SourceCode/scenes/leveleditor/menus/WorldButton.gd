extends Button

export var is_level = false

export var world_folder_name = "" setget _update_world_folder
export var level_filepath = "" setget _update_level_filepath
export var deleteable = true

var world_name = ""
var world_author = ""
var world_levels = []
var number_of_levels = 0

onready var title = $Title
onready var subtitle = $Subtitle
onready var delete_button = get_node_or_null("Delete")

signal world_selected
signal world_opened
signal world_delete_prompt

signal level_selected
signal level_opened
signal level_delete_prompt

var is_worldmap = false

func init_level(level_file_path : String, worldmap = false):
	is_worldmap = worldmap
	_update_level_filepath(level_file_path)

func init_world(world_folder_name : String):
	_update_world_folder(world_folder_name)

func _ready():
	if !deleteable: if delete_button: delete_button.hide()
	_on_Button_toggled(false)

func _update_level_filepath(new_value):
	level_filepath = new_value
	
	var level_name = ""
	
	if is_worldmap:
		level_name = "Worldmap"
		delete_button.hide()
	else:
		level_name = Global.get_level_attribute(level_filepath, "level_title")
	
	if !level_name:
		print("Unrecognised STC level at path: " + level_filepath)
		push_error("Unrecognised STC level at path: " + level_filepath)
		queue_free()
		return
	
	title.text = level_name
	subtitle.text = ""#level_author

func _update_world_folder(new_value):
	world_folder_name = new_value
	
	world_name = UserLevels.get_world_name(world_folder_name)
	world_author = UserLevels.get_world_author(world_folder_name)
	
	world_levels = UserLevels.get_levels_in_world(world_folder_name)
	number_of_levels = world_levels.size()
	
	title.text = world_name
	
	var levels_text = "level" if number_of_levels == 1 else "levels"
	
	subtitle.text = world_author + " - " + str(number_of_levels) + " " + levels_text

func _on_WorldButton_pressed():
	pressed = !pressed
	if pressed: emit_signal("world_opened", world_folder_name)
	else: emit_signal("world_selected", world_folder_name)

func _on_LevelButton_pressed():
	pressed = !pressed
	if pressed: emit_signal("level_opened", level_filepath)
	else: emit_signal("level_selected", level_filepath)

func _on_DeleteWorld_pressed():
	emit_signal("world_delete_prompt", world_folder_name)

func _on_DeleteLevel_pressed():
	emit_signal("level_delete_prompt", level_filepath)

func _on_Button_toggled(button_pressed):
	if button_pressed:
		title.modulate = Color(1,1,0)
		subtitle.modulate = Color(1,1,0)
	else:
		title.modulate = Color(1,1,1)
		subtitle.modulate = Color(1,1,1)


