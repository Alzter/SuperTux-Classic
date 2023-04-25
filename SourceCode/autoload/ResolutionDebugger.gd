extends CanvasLayer

onready var screen_res_label = $Control/VBoxContainer/ScreenResolution
onready var window_res_label = $Control/VBoxContainer/WindowResolution
onready var pixel_size_label = $Control/VBoxContainer/PixelSize

func _ready():
	ResolutionManager.connect("window_resized", self, "window_resized")
	window_resized()

func window_resized():
	screen_res_label.text = str(ResolutionManager.window_size.x) + " x " + str(ResolutionManager.window_size.y)
	window_res_label.text = str(ResolutionManager.window_resolution.x) + " x " + str(ResolutionManager.window_resolution.y)
	pixel_size_label.text = str(ResolutionManager.screen_shrink)
