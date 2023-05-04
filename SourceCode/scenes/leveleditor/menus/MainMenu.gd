extends Control

onready var menu_main = $MainMenu
onready var menu_create_world = $CreateWorldMenu

onready var button_world_create = $MainMenu/VBoxContainer/WorldCreate
onready var button_world_open = $MainMenu/VBoxContainer/WorldOpen
onready var button_exit = $MainMenu/VBoxContainer/ExitToMenu

func _ready():
	Scoreboard.hide()
	Music.stop_all()
	button_world_create.grab_focus()


func _on_WorldCreate_pressed():
	menu_main.hide()
	menu_create_world.popup()


func _on_ExitToMenu_pressed():
	Global.goto_title_screen()


func _on_WorldCreate_mouse_entered():
	button_world_create.grab_focus()


func _on_WorldOpen_mouse_entered():
	button_world_open.grab_focus()


func _on_ExitToMenu_mouse_entered():
	button_exit.grab_focus()


func _on_CreateWorldMenu_popup_hide():
	menu_main.show()
	button_world_create.grab_focus()
