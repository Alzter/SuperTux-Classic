extends Control

var options_data = null

onready var volume_music_slider = $Panel/VBoxContainer/MusicVolume/VolumeMusic
onready var volume_sfx_slider = $Panel/VBoxContainer/SFXVolume/VolumeSFX
onready var volume_ambience_slider = $Panel/VBoxContainer/AmbienceVolume/VolumeAmbience
onready var controls_button = $ControlsMenu/Panel/Controls
onready var done_button = $ControlsMenu/Panel/Done

onready var options_menu = $Panel

onready var controls_menu = $ControlsMenu

func _on_OptionsMenu_about_to_show():
	if !SaveManager.does_options_data_exist():
		Global.create_options_data()
		yield(Global, "options_data_created")
	options_data = SaveManager.get_options_data()
	load_options(options_data)
	apply_options()


func load_options(options_data : Dictionary):
	if options_data == null:
		push_error("No options data to load")
		return
	volume_music_slider.value = options_data.get("music_volume")
	volume_sfx_slider.value = options_data.get("sfx_volume")
	volume_ambience_slider.value = options_data.get("ambience_volume")

func save_slider_values_to_options_dictionary():
	options_data["music_volume"] = volume_music_slider.value
	options_data["sfx_volume"] = volume_sfx_slider.value
	options_data["ambience_volume"] = volume_ambience_slider.value

func save_options():
	print(options_data)
	if options_data == null:
		push_error("No options data to save")
		return
	SaveManager.save_options_data(options_data)

func _on_Done_pressed():
	hide()

func apply_options():
	save_slider_values_to_options_dictionary()
	Global.apply_options(options_data)

func _on_VolumeMusic_value_changed(value):
	apply_options()

func _on_VolumeSFX_value_changed(value):
	apply_options()

func _on_VolumeAmbience_value_changed(value):
	apply_options()

# ========================================================================================
# SAVE EVERYTHING
func _on_OptionsMenu_popup_hide():
	print("Save Options")
	save_slider_values_to_options_dictionary()
	save_options()

func _on_Controls_pressed():
	options_menu.modulate.a = 0
	controls_menu.popup()

func _on_Controls_mouse_entered():
	controls_button.grab_focus()

func _on_Done_mouse_entered():
	done_button.grab_focus()

func _on_ControlsMenu_popup_hide():
	options_menu.modulate.a = 1
