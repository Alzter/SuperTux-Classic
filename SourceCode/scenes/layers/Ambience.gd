extends AudioStreamPlayer

export var editor_params = ["sound", "volume_db", "pitch_scale"]

export var current_sound = "AmbienceSnow" setget _set_current_sound
var ambient_sounds_list = []

var sound = [] setget _set_sound_dropdown, _get_sound_dropdown

export var ambience_sounds_path = "res://sounds/ambience_loops/"
export var file_extension = ".mp3"

func _ready():
	_get_ambient_sounds()

func _get_ambient_sounds():
	var dir = Directory.new()
	
	if dir.dir_exists(ambience_sounds_path):
		var potential_sounds = Global.list_files_in_directory(ambience_sounds_path)
		
		for sound in potential_sounds:
			if sound.ends_with(file_extension):
				ambient_sounds_list.append(sound.trim_suffix(file_extension))

func _set_current_sound(new_value):
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
		stream.data = buffer
		file.close()
		play()

func _set_sound_dropdown(new_value):
	self.current_sound = new_value[0]
	self.ambient_sounds_list = new_value[1]

func _get_sound_dropdown():
	return [current_sound, ambient_sounds_list]
