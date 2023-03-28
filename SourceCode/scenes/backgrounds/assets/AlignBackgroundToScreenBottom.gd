extends ParallaxBackground

# For some reason godot makes it impossible to align parallaxbackgrounds to
# the bottom of the screen by default.

func _ready():
	ResolutionManager.connect("window_resized", self, "window_resized")

func window_resized():
	var offset = ResolutionManager.window_resolution.y - 480
	offset = max(offset, 0)
	scroll_base_offset.y = offset
