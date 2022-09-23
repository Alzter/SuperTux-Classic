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
export var credits_scene = ""
onready var new_game_button = $Menu/VBoxContainer/NewGame
onready var load_game_button = $Menu/VBoxContainer/LoadGame
onready var quit_button = $Menu/VBoxContainer/Quit
onready var new_game_warning = $Menu/NewGameWarning

func _ready():
	Music.play("Title")
	Scoreboard.hide()
	#new_game_button.disabled = SaveManager.has_savefile()
	load_game_button.disabled = !SaveManager.has_savefile()
	
	# Hide the "Quit Game" button if we're running the game
	# inside of the browser (on HTML5) or on mobile devices
	var is_on_mobile = OS.has_feature("Android") or OS.has_feature("iOS")
	var is_on_browser = OS.has_feature("HTML5")
	quit_button.visible = !is_on_browser and !is_on_mobile
	
	$Menu/VBoxContainer/NewGame.grab_focus()

func _on_NewGame_pressed():
	if SaveManager.has_savefile():
		new_game_warning.popup_centered()
	else: SaveManager.new_game()

func _on_NewGameWarning_confirmed():
	SaveManager.new_game()

func _on_LoadGame_pressed():
	SaveManager.load_game()

func _on_LevelSelectDebug_pressed():
	$FileDialog.popup()

func _on_FileDialog_file_selected(path):
	if path.ends_with(".tscn"):
		Global.goto_level(path)

func _on_Credits_pressed():
	Global.goto_scene(credits_scene)

func _on_BossDebug_pressed():
	Global.goto_level("res://scenes/levels/Level27BOSSBATTLE.tscn")

func _on_Quit_pressed():
	get_tree().quit()


# Focus related signals

func _on_NewGame_mouse_entered():
	$Menu/VBoxContainer/NewGame.grab_focus()

func _on_LoadGame_mouse_entered():
	$Menu/VBoxContainer/LoadGame.grab_focus()

func _on_Credits_mouse_entered():
	$Menu/VBoxContainer/Credits.grab_focus()

func _on_Quit_mouse_entered():
	$Menu/VBoxContainer/Quit.grab_focus()
