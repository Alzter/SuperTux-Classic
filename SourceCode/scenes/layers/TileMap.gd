extends TileMap

export var non_autotile_tiles = ["SnowDopeFish", "SnowFish"]

export var group_tiles = {
	"Water1" : ['Water1', 'Water2', 'Water3', 'Water4', 'WaterFill'],
	"Lava1" : ['Lava1', 'Lava2', 'Lava3', 'Lava4', 'LavaFill'],
}

# Returns true if the specified tile applies autotile rules, false if not.
# Decoration tiles (e.g. Dopefish) don't apply autotile rules, while
# most main tilesets do.
func get_autotile_status(tile_id : int):
	var tile_name = tile_set.tile_get_name(tile_id)
	return !non_autotile_tiles.has(tile_name)
