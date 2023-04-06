#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2022 Alexander Small <alexsmudgy20@gmail.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


extends Control

export var intro_scene = ""
export var options_scene = ""
export var credits_scene = ""
onready var title_content = $TitleContent

onready var start_game_button = $TitleContent/Menu/VBoxContainer/StartGame
onready var bonus_levels_button = $TitleContent/Menu/VBoxContainer/BonusLevels
onready var options_button = $TitleContent/Menu/VBoxContainer/Options
onready var credits_button = $TitleContent/Menu/VBoxContainer/Credits
onready var quit_button = $TitleContent/Menu/VBoxContainer/Quit

onready var new_game_warning = $TitleContent/Menu/NewGameWarning
onready var options_menu = $OptionsMenu
onready var bonus_levels_menu = $BonusLevelsMenu

export var default_world = "world1"

func _ready():
	Music.play("Title")
	Scoreboard.hide()
	WorldmapManager.reset()
	
	# Transfer save-files made in v0.2.0 to the current save directory if they exist.
	if SaveManager.has_old_savefile():
		SaveManager.transfer_old_savefile_to_new_save_path()
	
	# Hide the "Quit Game" button if we're running the game
	# inside of the browser (on HTML5) or on mobile devices
	var is_on_mobile = OS.has_feature("mobile")
	var is_on_browser = OS.has_feature("HTML5")
	quit_button.visible = !is_on_browser and !is_on_mobile and !MobileControls.is_using_mobile
	
	start_game_button.grab_focus()

func _on_NewGame_pressed():
	if SaveManager.has_savefile(default_world):
		new_game_warning.popup_centered()
	else: SaveManager.new_game(intro_scene)

func _on_NewGameWarning_confirmed():
	SaveManager.new_game(intro_scene)

func _on_LoadGame_pressed():
	SaveManager.load_game(default_world)

func _on_LevelSelectDebug_pressed():
	$FileDialog.popup()

func _on_FileDialog_file_selected(path):
	if path.ends_with(".tscn"):
		Global.goto_level(path)

func _on_Options_pressed():
	title_content.hide()
	options_menu.popup()

func _on_Credits_pressed():
	Global.goto_scene(credits_scene)

func _on_BossDebug_pressed():
	Global.goto_level("res://scenes/levels/bonus2/Grumboss.tscn")

func _on_Quit_pressed():
	get_tree().quit()

# Focus related signals

func _on_Options_mouse_entered():
	options_button.grab_focus()

func _on_Credits_mouse_entered():
	credits_button.grab_focus()

func _on_Quit_mouse_entered():
	quit_button.grab_focus()

func _on_OptionsMenu_popup_hide():
	title_content.show()
	options_button.grab_focus()

func _on_BonusLevels_mouse_entered():
	bonus_levels_button.grab_focus()

func _on_BonusLevels_pressed():
	title_content.hide()
	bonus_levels_menu.popup()

func _on_BonusLevelsMenu_popup_hide():
	title_content.show()
	bonus_levels_button.grab_focus()
