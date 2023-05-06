extends Button

export var world_folder_name = "" setget update_world_folder
var world_name = ""
var world_author = ""
var world_levels = []
var number_of_levels = 0

onready var title = $Title
onready var subtitle = $Subtitle

func init(world_folder_name : String):
	update_world_folder(world_folder_name)

func update_world_folder(new_value):
	world_folder_name = new_value
	
	world_name = UserLevels.get_world_name(world_folder_name)
	world_author = UserLevels.get_world_author(world_folder_name)
	
	world_levels = UserLevels.get_levels_in_world(world_folder_name)
	number_of_levels = world_levels.size()
	
	title.text = world_name
	
	var levels_text = "level" if number_of_levels == 1 else "levels"
	
	subtitle.text = world_author + " - " + str(number_of_levels) + " " + levels_text

func _on_DeleteWorld_pressed():
	pass # Replace with function body.
