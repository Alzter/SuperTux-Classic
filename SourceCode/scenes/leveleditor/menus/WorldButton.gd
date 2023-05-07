extends Button

export var is_level = false

export var world_folder_name = "" setget update_world_folder
var world_name = ""
var world_author = ""
var world_levels = []
var number_of_levels = 0

onready var title = $Title
onready var subtitle = $Subtitle

signal world_selected
signal world_opened
signal world_delete_prompt

func init_level(level_file_path : String):
	return

func init_world(world_folder_name : String):
	update_world_folder(world_folder_name)

func _ready():
	_on_Button_toggled(false)


func update_world_folder(new_value):
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

func _on_DeleteWorld_pressed():
	emit_signal("world_delete_prompt", world_folder_name)


func _on_Button_toggled(button_pressed):
	if button_pressed:
		title.modulate = Color(1,1,0)
		subtitle.modulate = Color(1,1,0)
	else:
		title.modulate = Color(1,1,1)
		subtitle.modulate = Color(1,1,1)
