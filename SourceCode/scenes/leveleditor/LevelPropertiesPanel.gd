extends PopupDialog

onready var level_properties = get_node("VBoxContainer/PanelContainer/ScrollContainer/LevelProperties")

onready var level_name = level_properties.get_node("EditLevelName/Name")
onready var level_author = level_properties.get_node("EditLevelAuthor/Author")
onready var level_music = level_properties.get_node("EditLevelMusic/Music")
onready var level_timer_enabled = level_properties.get_node("EditLevelTimer/TimerEnabled")
onready var level_time = level_properties.get_node("EditLevelTimer/Time")
onready var level_gravity = level_properties.get_node("EditLevelGravity/Gravity")
onready var level_autoscroll_speed = level_properties.get_node("EditLevelAutoscroll/AutoscrollSpeed")

var music_tracks := {}
var custom_music_files := {}

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
	
	# -------------------------------------------------------------------------
	# "Add custom track..." button
	var plus_icon = preload("res://images/editor/icons/add_small.png")
	
	level_music.add_icon_item(plus_icon, "Add custom track...", id)
	music_tracks["Custom"] = id
	id += 1
	
	#level_music.add_separator()
	
	# -------------------------------------------------------------------------
	
	# Load custom music tracks
	custom_music_files = {}
	
	var custom_tracks = UserLevels.get_custom_music_tracks_for_world()
	if custom_tracks:
		for song_file in custom_tracks:
			
			var custom_song_extension = song_file.get_extension()
			var custom_song_name = song_file.get_file().trim_suffix("." + custom_song_extension)
			
			custom_music_files[custom_song_name] = song_file
			
			level_music.add_item(custom_song_name, id)
			music_tracks[custom_song_name] = id
			id += 1
		
		#level_music.add_separator()
	
	# -------------------------------------------------------------------------
	
	# Load all base-game music tracks (add in alphabetical order)
	var songs = Music.songs
	songs.sort()
	
	for song in songs:
		print(str(song) + ", " + str(id))
		level_music.add_item(song, id)
		music_tracks[song] = id
		id += 1

# WHY GODOT?! WHY MUST I JUMP THROUGH SUCH HOOPS?!
func _set_music_to_song(song_name : String):
	
	# Translate a custom song filepath from URL to string format
	var id := 0
	for custom_song_file in custom_music_files.values():
		if custom_song_file == song_name:
			var custom_song_name = custom_music_files.keys()[id]
			song_name = custom_song_name
		id += 1
	
	if music_tracks.has(song_name):
		var song_id = music_tracks.get(song_name)
		level_music.select(song_id)

func _on_Name_text_changed(new_text):
	if level:
		level.level_title = new_text
		Global.clear_level_cache(UserLevels.current_level)

func _on_Author_text_changed(new_text):
	if level:
		level.level_author = new_text
		Global.clear_level_cache(UserLevels.current_level)

# SET LEVEL MUSIC TO ITEM SELECTED ON SONG SELECTOR
func _on_Music_item_selected(index):
	# "Add custom song" button
	if index == 0:
		_set_music_to_song(level.music)
		print("Add custom song...")
		
	elif level:
		
		# Set music to selected song.
		for song_id in music_tracks.values():
			if song_id == index:
				var song_name = music_tracks.keys()[song_id]
				
				# If song is custom music track,
				# actually set the level music to the filepath (URL)
				# of the custom music track.
				if custom_music_files.has(song_name):
					song_name = custom_music_files.get(song_name)
				
				level.music = song_name

func _on_TimerEnabled_toggled(button_pressed):
	if level: level.uses_timer = button_pressed
	level_time.editable = button_pressed

func _on_Time_value_changed(value):
	if level: level.time = value

func _on_Gravity_value_changed(value):
	if level: level.gravity = value

func _on_AutoscrollSpeed_value_changed(value):
	if level: level.autoscroll_speed = value

func _on_HideLevelProperties_pressed():
	hide()

func _input(event):
	if !visible: return
	if Input.is_action_pressed("ui_accept"):
		yield(get_tree(), "idle_frame") # This has to be here or else the play level input registers too
		hide()
