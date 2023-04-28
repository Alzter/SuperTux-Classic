extends Button

var tile_id = null
var tileset = null
signal tile_button_pressed(button_node, tile_id)

func _ready():
	print(tile_id, tileset)

func _on_TileButton_pressed():
	emit_signal("tile_button_pressed", self, tile_id)
