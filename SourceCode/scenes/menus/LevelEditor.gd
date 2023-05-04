extends Control

onready var button_world_create = $Panel/VBoxContainer/WorldCreate
onready var button_world_open = $Panel/VBoxContainer/WorldOpen
onready var button_exit = $Panel/VBoxContainer/ExitToMenu

func _ready():
	Scoreboard.hide()
	Music.stop_all()
	button_world_create.grab_focus()


func _on_WorldCreate_pressed():
	pass # Replace with function body.


func _on_ExitToMenu_pressed():
	Global.goto_title_screen()


func _on_WorldCreate_mouse_entered():
	button_world_create.grab_focus()


func _on_WorldOpen_mouse_entered():
	button_world_open.grab_focus()


func _on_ExitToMenu_mouse_entered():
	button_exit.grab_focus()
