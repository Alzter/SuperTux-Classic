extends Button

export var play_texture : Texture
export var play_from_start_texture : Texture
export var edit_texture : Texture

onready var label = $Label
onready var button_icon = $Icon

func _ready():
	update()

func _input(event):
	if Input.is_action_just_pressed("editor_play_from_start"): update()
	if Input.is_action_just_released("editor_play_from_start"): update()

# Update the visuals on the edit button
func update():
	var label_text = null
	var texture = null
	
	if !owner.edit_mode:
		label.text = "EDIT"
		button_icon.texture = edit_texture
	
	elif Input.is_action_pressed("editor_play_from_start") or owner.edit_objects_enabled:
		label.text = "PLAY FROM START"
		button_icon.texture = play_from_start_texture
	else:
		label.text = "PLAY"
		button_icon.texture = play_texture
	
	
