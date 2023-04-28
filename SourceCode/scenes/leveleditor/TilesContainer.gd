extends GridContainer

export var tile_button_scene : PackedScene

var current_tileset = null

# Fills the Tiles container with all the tiles within the tileset of the tilemap
func show_tiles_from_tilemap(tilemap : TileMap):
	
	# Get the tilemap's TileSet
	var tileset = tilemap.get_tileset()
	
	# If we're already using the tileset, don't repopulatie the tiles container
	if current_tileset == tileset: return
	
	current_tileset = tileset
	
	var tile_ids = tileset.get_tiles_ids()
	
	for tile in tile_ids:
		var tile_button = tile_button_scene.instance()
		tile_button.tile_id = tile
		tile_button.tileset = current_tileset
		add_child(tile_button)
		tile_button.set_owner(self)

# Empties all tiles in the tile container
func empty_tiles():
	current_tileset = null
	
	for tile_button in get_children():
		tile_button.queue_free()
