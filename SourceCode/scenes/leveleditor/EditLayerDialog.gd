extends PopupDialog

var layer_being_edited : Node = null

func appear(layer_to_edit : Node):
	layer_being_edited = layer_to_edit
	popup()

func _on_EditLayerDialog_about_to_show():
	print(layer_being_edited)

func _on_ConfirmEditLayer_pressed():
	hide()

func _on_EditLayerDialog_popup_hide():
	layer_being_edited = null
