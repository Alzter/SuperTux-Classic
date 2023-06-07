extends Button

var tileset : TileSet = null
var tile_id : int = -1 setget update_current_tile_id
signal tile_button_pressed(tile_id)
signal update_tile_preview_texture(texture)

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
		#print(tileset.tile_get_name(tile_id))
		
		var sprite_position = tileset.tile_get_region(tile_id).position
		sprite_position += tileset.autotile_get_icon_coordinate(tile_id) * Global.TILE_SIZE
		
		sprite.region_rect.position = sprite_position
		
	else:
		sprite.region_rect = tileset.tile_get_region(tile_id)
		
		# Scale down the tile sprite if the tile is larger than 32x32
		var rect_size = max(sprite.region_rect.size.x, sprite.region_rect.size.y)
		sprite.scale = Vector2.ONE * (Global.TILE_SIZE / rect_size)

func _on_TileButton_pressed():
	emit_signal("tile_button_pressed", tile_id)
	set_preview_texture()

func set_preview_texture():
	emit_signal("update_tile_preview_texture", sprite.texture, sprite.region_rect)

func flip_tiles_toggled(flip_x_enabled : bool):
	sprite.flip_h = flip_x_enabled
