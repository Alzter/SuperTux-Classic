extends AudioStreamPlayer

export var editor_params = ["volume", "pitch"] # "sound"

export var volume = -10 setget _set_volume, _get_volume
export var pitch = 1.25 setget _set_pitch, _get_pitch

export var using_default_values = true

export var current_sound = "AmbienceSnow" setget _set_current_sound

export var max_volume = 20

var ambient_sounds_list = []

var sound = [] setget _set_sound_dropdown, _get_sound_dropdown

export var ambience_sounds_path = "res://sounds/ambience_loops/"
export var file_extension = ".mp3"

func _ready():
	if !using_default_values:
		volume_db = volume
		pitch_scale = pitch
	
	#_get_ambient_sounds()

func _get_ambient_sounds():
	var dir = Directory.new()
	
	if dir.dir_exists(ambience_sounds_path):
		var potential_sounds = Global.list_files_in_directory(ambience_sounds_path)
		
		for sound in potential_sounds:
			if sound.ends_with(file_extension):
				ambient_sounds_list.append(sound.trim_suffix(file_extension))

func _set_current_sound(new_value):
	if new_value == current_sound: return
	
	current_sound = new_value
	
	var sound_file = ambience_sounds_path + current_sound + file_extension
	_set_audio_stream_to_file(sound_file)

func _set_audio_stream_to_file(file_path):
	call_deferred("_deferred_set_audio_stream_to_file", file_path)

func _deferred_set_audio_stream_to_file(file_path):
	var file = File.new()
	if file.file_exists(file_path):
		file.open(file_path, File.READ)
		
		var buffer = file.get_buffer(file.get_len())
		
		if buffer:
			stream.data = buffer
			play()
		
		file.close()

func _set_sound_dropdown(new_value):
	self.current_sound = new_value[0]
	self.ambient_sounds_list = new_value[1]

func _get_sound_dropdown():
	return [current_sound, ambient_sounds_list]

func _set_volume(new_value):
	new_value = min(new_value, max_volume)
	using_default_values = false
	volume = new_value
	volume_db = new_value

func _get_volume(): return volume_db

func _set_pitch(new_value):
	new_value = clamp(new_value, 0.1, 30.0)
	using_default_values = false
	pitch = new_value
	pitch_scale = new_value

func _get_pitch(): return pitch_scale
