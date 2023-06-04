extends PopupDialog

onready var level_properties = get_node("VBoxContainer/PanelContainer/LevelProperties")

onready var level_name = level_properties.get_node("EditLevelName/Name")
onready var level_author = level_properties.get_node("EditLevelAuthor/Author")
onready var level_music = level_properties.get_node("EditLevelMusic/Music")
onready var level_timer_enabled = level_properties.get_node("EditLevelTimer/TimerEnabled")
onready var level_time = level_properties.get_node("EditLevelTimer/Time")
onready var level_gravity = level_properties.get_node("EditLevelGravity/Gravity")
onready var level_autoscroll_speed = level_properties.get_node("EditLevelAutoscroll/AutoscrollSpeed")

var music_tracks : Dictionary = {}

var level = null

func _on_LevelPropertiesDialog_about_to_show():
	level = owner.level
	if level:
		level_name.text = level.level_title
		level_author.text = level.level_author
		_update_music_list()
		_set_music_to_song(level.music)
		level_timer_enabled.pressed = level.uses_timer
		level_time.value = level.time
		level_time.editable = level_timer_enabled.pressed
		level_gravity.value = level.gravity
		level_autoscroll_speed.value = level.autoscroll_speed

func _update_music_list():
	var id = 0
	music_tracks = {}
	level_music.clear()
	for song in Music.songs:
		level_music.add_item(song, id)
		music_tracks[song] = id
		id += 1

# WHY GODOT?! WHY MUST I JUMP THROUGH SUCH HOOPS?!
func _set_music_to_song(song_name : String):
	if music_tracks.has(song_name):
		var song_id = music_tracks.get(song_name)
		level_music.select(song_id)

func _on_Name_text_changed(new_text):
	if level: level.level_title = new_text

func _on_Author_text_changed(new_text):
	if level: level.level_author = new_text

func _on_Music_item_selected(index):
	if level:
		for song_id in music_tracks.values():
			if song_id == index:
				var song_name = music_tracks.keys()[song_id]
				level.music = song_name

func _on_TimerEnabled_toggled(button_pressed):
	if level: level.uses_timer = button_pressed
	level_time.editable = button_pressed
	print(button_pressed)

func _on_Time_value_changed(value):
	if level: level.time = value

func _on_Gravity_value_changed(value):
	if level: level.gravity = value

func _on_AutoscrollSpeed_value_changed(value):
	if level: level.autoscroll_speed = value

func _on_HideLevelProperties_pressed():
	hide()
