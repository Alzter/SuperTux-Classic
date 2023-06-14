extends Control

export var menu_music = ""
onready var menu_main = $MainMenu
onready var menu_create_world = $CreateWorldMenu
onready var menu_open_world = $OpenWorldMenu
onready var menu_world = $WorldMenu

onready var button_world_create = $MainMenu/VBoxContainer/PanelContainer/MenuItems/WorldCreate
onready var button_world_open = $MainMenu/VBoxContainer/PanelContainer/MenuItems/WorldOpen
onready var button_worlds_folder_open = $MainMenu/VBoxContainer/PanelContainer/MenuItems/OpenWorldFolder
onready var button_exit = $MainMenu/VBoxContainer/ExitToMenu

func _ready():
	Music.set_editor_music(false)
	if menu_music != "": Music.play(menu_music)
	
	UserLevels.current_world = null
	ResolutionManager.enable_zoom_in = false
	Scoreboard.hide()
	Music.stop_all()
	button_world_create.grab_focus()
	
	if !UserLevels.custom_content_supported:
		button_worlds_folder_open.disabled = true
	
	menu_create_world.connect("show_world_menu", self, "open_world_menu")
	
	Global.connect("open_world_menu", self, "open_world_menu")


func _on_WorldCreate_mouse_entered():
	button_world_create.grab_focus()

func _on_WorldCreate_pressed():
	menu_main.hide()
	menu_create_world.popup()

func _on_WorldOpen_mouse_entered():
	button_world_open.grab_focus()

func _on_WorldOpen_pressed():
	menu_main.hide()
	menu_open_world.popup()

func _on_ExitToMenu_mouse_entered():
	button_exit.grab_focus()

func _on_ExitToMenu_pressed():
	UserLevels.current_world = null
	Global.goto_title_screen()

func _on_OpenWorldFolder_mouse_entered():
	button_worlds_folder_open.grab_focus()

func _on_OpenWorldFolder_pressed():
	UserLevels.open_user_worlds_folder()

func _on_CreateWorldMenu_popup_hide():
	menu_main.show()
	button_world_create.grab_focus()

func _on_OpenWorldMenu_popup_hide():
	menu_main.show()
	button_world_open.grab_focus()

func _on_WorldMenu_popup_hide():
	menu_main.show()
	button_world_open.grab_focus()

# Opens the world menu for a specified world.
func open_world_menu(world_folder_name : String):
	UserLevels.current_world = world_folder_name
	menu_main.hide()
	menu_world.popup()
