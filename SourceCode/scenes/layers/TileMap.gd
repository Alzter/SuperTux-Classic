extends TileMap

# These tiles won't apply autotile rules in the editor.
export var non_autotile_tiles = ["SnowDopeFish", "SnowFish"]

# These tiles will be treated as a single tile in the editor.
export var group_tiles = {
	"Water1" : ['Water1', 'Water2', 'Water3', 'Water4', 'WaterFill'],
	"Lava1" : ['Lava1', 'Lava2', 'Lava3', 'Lava4', 'LavaFill'],
}

# These tiles won't show up in the editor.
export var ignore_tiles = [
	"Invisible", "InvisibleUniSolid"
]

# Returns true if the specified tile applies autotile rules, false if not.
# Decoration tiles (e.g. Dopefish) don't apply autotile rules, while
# most main tilesets do.
func get_autotile_status(tile_id : int):
	var tile_name = tile_set.tile_get_name(tile_id)
	return !non_autotile_tiles.has(tile_name)
