extends PopupDialog

onready var button_create_level = $VBoxContainer/PanelContainer/ButtonList/HSplitContainer/CreateLevel
onready var button_open_level = $VBoxContainer/PanelContainer/ButtonList/HSplitContainer/OpenLevel
onready var button_edit_world = $VBoxContainer/PanelContainer/ButtonList/EditWorldProperties
onready var button_world_folder = $VBoxContainer/PanelContainer/ButtonList/HSplitContainer2/OpenWorldFolder

onready var button_back = $VBoxContainer/Back
onready var label_world_name = $VBoxContainer/WorldName

onready var dialog_open_level = $SelectLevelDialog
onready var dialog_edit_world_properties = $EditWorldMenu

func _ready():
	dialog_open_level.connect("level_opened", self, "level_opened")

func _on_WorldMenu_about_to_show():
	if !UserLevels.current_world:
		hide()
		push_error("Error creating World menu dialog: No user world was specified to open in UserLevels")
		return
	
	get_world_attributes()
	
	if !UserLevels.custom_content_supported:
		button_world_folder.disabled = true
	
	button_open_level.grab_focus()

func get_world_attributes():
	if !UserLevels.current_world: return
	if !label_world_name: return
	
	var world_name = UserLevels.get_world_name()
	label_world_name.bbcode_text = "[center][wave]" + world_name

func _on_Back_pressed():
	hide()

func _on_OpenLevel_pressed():
	dialog_open_level.popup()

func _on_CreateLevel_pressed():
	var level_filepath = UserLevels.create_level_in_world()
	if level_filepath != "":
		Global.load_level_editor_with_level(level_filepath)
	else:
		# Give the user an error message for creating the level
		pass

func _on_EditWorldProperties_pressed():
	dialog_edit_world_properties.popup()

func _on_SelectLevelDialog_popup_hide():
	button_open_level.grab_focus()

func _on_EditWorldMenu_hide():
	get_world_attributes()

func level_opened(level_filepath : String):
	Global.load_level_editor_with_level(level_filepath)

func _on_OpenWorldFolder_pressed():
	UserLevels.open_user_world_folder(UserLevels.current_world)
