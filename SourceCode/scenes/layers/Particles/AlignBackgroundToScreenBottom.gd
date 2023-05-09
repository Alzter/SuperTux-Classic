extends ParallaxBackground

# For some reason godot makes it impossible to align parallaxbackgrounds to
# the bottom of the screen by default.

func _ready():
	ResolutionManager.connect("window_resized", self, "window_resized")
	Global.connect("level_ready", self, "window_resized")
	window_resized()

func window_resized():
	var offset = ResolutionManager.window_resolution.y - 480
	
	var camera = Global.get_current_camera()
	
	var zoom = 0
	
	if camera:
		zoom = abs(1 - camera.zoom.y)
		offset -= 480 * ResolutionManager.window_resolution.y * zoom
	
	#print(zoom)
	if zoom != 0: offset = max(offset, 0)
	scroll_base_offset.y = offset
