extends Button

var tileset : TileSet = null
var tile_id : int = -1 setget update_current_tile_id
signal tile_button_pressed(button_node, tile_id)

onready var sprite = $Control/Sprite

func update_current_tile_id(new_value):
	if !tileset:
		push_error("Error updating Tile ID of Tile Button - you must specify a tileset first!")
		return
	
	tile_id = new_value
	
	var tile_texture = tileset.tile_get_texture(tile_id)
	var tile_texture_size = tileset.tile_get_region(tile_id).size
	sprite.set_texture(tile_texture)
	
	if tileset.tile_get_tile_mode(tile_id) == 1:
		sprite.region_rect.position = tileset.autotile_get_icon_coordinate(tile_id) * Global.TILE_SIZE
	else:
		sprite.region_rect = tileset.tile_get_region(tile_id)
		
		# Scale down the tile sprite if the tile is larger than 32x32
		var rect_size = max(sprite.region_rect.size.x, sprite.region_rect.size.y)
		sprite.scale = Vector2.ONE * (Global.TILE_SIZE / rect_size)

func _on_TileButton_pressed():
	emit_signal("tile_button_pressed", self, tile_id)