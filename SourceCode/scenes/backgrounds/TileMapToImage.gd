extends Viewport

onready var tilemap = $TileMap

func _ready():
	size = tilemap.get_used_rect().size * 32
	get_tree().get_root().set_transparent_background(true)

func _process(delta):
	if Input.is_action_just_pressed("jump"):
		takePhoto()

func takePhoto():
	print("Snap")
	yield(VisualServer,"frame_post_draw")
	
	var img2=get_viewport().get_texture().get_data()

	#img2.flip_y()
	img2.convert(Image.FORMAT_RGBA8)
	img2.save_png("BackgroundExport.png")
