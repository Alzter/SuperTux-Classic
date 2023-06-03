extends Popup

onready var button_story_mode = $Panel/VBoxContainer/PanelContainer/VBoxContainer/StoryMode
onready var button_bonus_levels = $Panel/VBoxContainer/PanelContainer/VBoxContainer/HSplitContainer/BonusLevels
onready var button_custom_levels = $Panel/VBoxContainer/PanelContainer/VBoxContainer/HSplitContainer/CustomLevels
onready var button_back = $Panel/VBoxContainer/Back

onready var menu_bonus_levels = $BonusLevelsMenu
onready var menu_custom_levels = $CustomLevelsMenu


func _on_StartGameMenu_about_to_show():
	button_story_mode.grab_focus()


func _on_BonusLevels_focus_entered():
	button_bonus_levels.grab_focus()

func _on_BonusLevels_pressed():
	menu_bonus_levels.popup()

func _on_CustomLevels_focus_entered():
	button_custom_levels.grab_focus()

func _on_CustomLevels_pressed():
	menu_custom_levels.popup()

func _on_Back_focus_entered():
	button_back.grab_focus()

func _on_Back_pressed():
	hide()

func _on_BonusLevelsMenu_popup_hide():
	button_bonus_levels.grab_focus()
