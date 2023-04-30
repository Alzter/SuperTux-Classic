extends GridContainer

export var tile_button_scene : PackedScene

var current_tileset = null

signal update_selected_tile

# Fills the Tiles container with all the tiles within the tileset of the tilemap
func show_tiles_from_tilemap(tilemap : TileMap):
	
	# Get the tilemap's TileSet
	var tileset = tilemap.get_tileset()
	
	# If we're already using the tileset, don't repopulatie the tiles container
	if current_tileset == tileset: return
	
	empty_tiles()
	current_tileset = tileset
	
	var tile_ids = tileset.get_tiles_ids()
	
	for tile in tile_ids:
		var tile_button = tile_button_scene.instance()
		add_child(tile_button)
		tile_button.set_owner(self)
		tile_button.connect("tile_button_pressed", self, "update_selected_tile")
		tile_button.tileset = current_tileset
		tile_button.tile_id = tile

# Empties all tiles in the tile container
func empty_tiles():
	current_tileset = null
	
	for tile_button in get_children():
		tile_button.queue_free()

func update_selected_tile(tile_button_node : Control, selected_tile_id : int):
	emit_signal("update_selected_tile", selected_tile_id)
	for tile_button in get_children():
		tile_button.disabled = tile_button.tile_id == selected_tile_id
