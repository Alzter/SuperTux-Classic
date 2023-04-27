extends Popup

onready var back_button = $Panel/Back

func _on_Back_mouse_entered():
	back_button.grab_focus()
	
func _on_Back_pressed():
	hide()

func _on_Contrib_pressed():
	get_parent().contrib_menu.show()
	self.hide()
