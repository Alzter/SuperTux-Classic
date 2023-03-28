extends ParallaxBackground

# For some reason godot makes it impossible to align parallaxbackgrounds to
# the bottom of the screen by default.

func _ready():
	ResolutionManager.connect("window_resized", self, "window_resized")
	Global.connect("player_loaded", self, "window_resized")

func window_resized():
	var offset = ResolutionManager.window_resolution.y - 480
	var camera = Global.get_current_camera()
	offset = max(offset, 0)
	scroll_base_offset.y = offset
