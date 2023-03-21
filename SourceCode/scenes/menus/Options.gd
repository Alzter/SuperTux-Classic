extends Control

func _on_Done_pressed():
	hide()

func _on_VolumeMusic_value_changed(value):
	AudioServer.set_bus_volume_db(2, value)

func _on_VolumeSFX_value_changed(value):
	AudioServer.set_bus_volume_db(1, value)

func _on_VolumeAmbience_value_changed(value):
	AudioServer.set_bus_volume_db(3, value)
	AudioServer.set_bus_volume_db(4, value)
