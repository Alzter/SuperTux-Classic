
extends CanvasLayer

onready var menu = $Control
onready var menu_items = $Control/CenterContainer
onready var options_menu = $Control/OptionsMenu

onready var button_continue = $Control/CenterContainer/VBoxContainer/Continue
onready var button_options = $Control/CenterContainer/VBoxContainer/Options
onready var button_quit = $Control/CenterContainer/VBoxContainer/Quit

var paused = false setget _set_paused

signal pause_changed
signal save_and_quit

func _ready():
	show()
	
	# Make the music mute if we pause the game.
	Music.pause_mode = PAUSE_MODE_INHERIT
	menu.hide()
	Global.can_pause = true

func _input(event):
	if !Global.can_pause: return
	if Global.is_popup_visible(): return
	
	if Input.is_action_just_pressed("ui_cancel"):
		self.paused = !paused

func _on_Control_visibility_changed():
	if $Control.visible == true:
		button_continue.grab_focus()

func _set_paused(new_value):
	paused = new_value
	get_tree().paused = paused
	menu.visible = paused
	
	if !get_parent().edit_mode:
		Scoreboard.level_timer.paused = paused
	
	emit_signal("pause_changed", paused)

func _on_Continue_pressed():
	self.paused = false

func _on_Continue_mouse_entered():
	button_continue.grab_focus()

func _on_Options_pressed():
	menu_items.modulate.a = 0
	options_menu.popup()

func _on_OptionsMenu_popup_hide():
	menu_items.modulate.a = 1
	button_options.grab_focus()

func _on_Options_mouse_entered():
	button_options.grab_focus()

func _on_Quit_pressed():
	var par = get_parent()
	if par.edit_mode:
		emit_signal("save_and_quit")
	else:
		par._deferred_enter_edit_mode()
		par.save_level()
		_set_paused(false)

func _on_Quit_mouse_entered():
	button_quit.grab_focus()

