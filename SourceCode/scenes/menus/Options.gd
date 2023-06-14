extends Control

var options_data = null
var loading_options = false

onready var options_container = $Panel/PanelContainer/ScrollContainer/Options
onready var volume_music_slider = options_container.get_node("MusicVolume/VolumeMusic")
onready var volume_sfx_slider = options_container.get_node("SFXVolume/VolumeSFX")
onready var volume_ambience_slider = options_container.get_node("AmbienceVolume/VolumeAmbience")
onready var auto_run_checkbox = options_container.get_node("AutoRun/AutoRun")
onready var controls_button = options_container.get_node("Controls")
onready var privacy_policy_button = options_container.get_node("PrivacyPolicy")
onready var done_button = $ControlsMenu/Panel/Done

onready var options_menu = $Panel

onready var controls_menu = $ControlsMenu

func _on_OptionsMenu_about_to_show():
	if !SaveManager.does_options_data_exist():
		Global.create_options_data()
		yield(Global, "options_data_created")
	options_data = SaveManager.get_options_data()
	load_options(options_data)
	#apply_options()
	if MobileControls.is_using_mobile:
		controls_button.hide()

func load_options(options_data : Dictionary):
	if options_data == null:
		push_error("No options data to load")
		return
	
	loading_options = true
	
	if options_data.has("music_volume"):
		volume_music_slider.value = options_data.get("music_volume")
	
	if options_data.has("sfx_volume"):
		volume_sfx_slider.value = options_data.get("sfx_volume")
	
	if options_data.has("ambience_volume"):
		volume_ambience_slider.value = options_data.get("ambience_volume")
	
	if options_data.has("auto_run"):
		#print("AUTO RUN")
		#print(options_data.get("auto_run"))
		auto_run_checkbox.pressed = options_data.get("auto_run")
	
	loading_options = false

func update_options_dictionary():
	options_data["music_volume"] = volume_music_slider.value
	options_data["sfx_volume"] = volume_sfx_slider.value
	options_data["ambience_volume"] = volume_ambience_slider.value
	options_data["auto_run"] = auto_run_checkbox.pressed

func save_options():
	if options_data == null:
		push_error("No options data to save")
		return
	SaveManager.save_options_data(options_data)

func _on_Done_pressed():
	hide()

func apply_options():
	update_options_dictionary()
	Global.apply_options(options_data)

func _on_AutoRun_toggled(button_pressed):
	if !loading_options: apply_options()

func _on_VolumeMusic_value_changed(value):
	if !loading_options: apply_options()

func _on_VolumeSFX_value_changed(value):
	if !loading_options: apply_options()

func _on_VolumeAmbience_value_changed(value):
	if !loading_options: apply_options()

# ========================================================================================
# SAVE EVERYTHING
func _on_OptionsMenu_popup_hide():
	update_options_dictionary()
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


func _on_PrivacyPolicy_pressed():
	OS.shell_open(Global.privacy_policy_url)

func _on_PrivacyPolicy_mouse_entered():
	privacy_policy_button.grab_focus()
