extends TileMap

export var editor_params = [
	"solid", "liquid", "z_index", "multiply_color", "overlay_color"
	]

onready var solid : bool = get_collision_layer_bit(0) setget _update_solidity
onready var liquid : bool = get_collision_layer_bit(7) setget _update_liquid_collision
onready var multiply_color : Color = modulate setget _update_multiply_color

var overlay_color : Color = Color(0.5,0.5,0.5,0.5) setget _update_overlay_color

var expand_on_bottom = true

var is_in_worldmap = false

export var unique_material = false

export var worldmap_tileset : TileSet

func _ready():
	if is_in_worldmap: set_tileset(worldmap_tileset)
	
	if unique_material: use_parent_material = false
	
	var overlay = material.get_shader_param("overlay_color")
	
	if overlay is Plane:
		overlay_color = Color(overlay.x, overlay.y, overlay.z, overlay.d)
	else:
		overlay_color = overlay
	
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

# These tiles use custom autotiling rules.
export var custom_autotile_tiles = [
	'Water1', 'Water2', 'Water3', 'Water4', 'WaterFill',
	'Lava1', 'Lava2', 'Lava3', 'Lava4', 'LavaFill'
]

# Returns true if the specified tile applies autotile rules, false if not.
# Decoration tiles (e.g. Dopefish) don't apply autotile rules, while
# most main tilesets do.
func get_autotile_status(tile_id : int):
	var tile_name = tile_set.tile_get_name(tile_id)
	return !non_autotile_tiles.has(tile_name)

# Applies custom autotile rules to all tiles inside and adjacent of tile_position.
func apply_custom_autotile_rules(tile_position : Vector2):
	
	# Make a Rect2 containing all the tiles we need to update the bitmask for.
	var tile_rect = Rect2(tile_position - Vector2.ONE, Vector2.ONE * 2)
	
	# Iterate through every tile in this rectangle by updating its tile
	# based on autotiling rules we establish in the function
	# called "_apply_custom_autotile_rules_to_tile"
	for y in tile_rect.size.y + 1:
		for x in tile_rect.size.x + 1:
			var tile_coords = tile_rect.position + Vector2(x,y)
			var tile_id = get_cellv(tile_coords)
			var tile_name = tile_set.tile_get_name(tile_id)
			
			if custom_autotile_tiles.has(tile_name):
				_apply_custom_autotile_rules_to_tile(tile_coords)

# Applies custom autotile rules for specific tiles, such as water and lava.
# Godot's autotiling functionality is limited so we have to make custom rules
# for certain tiles like these.
func _apply_custom_autotile_rules_to_tile(tile_position : Vector2):
	var tile_id = get_cellv(tile_position)
	var tile_to_use = _get_autotile_tile_to_use_at(tile_position, tile_id)
	
	if tile_to_use != tile_id:
		set_cellv(tile_position, tile_to_use)

# Gets the specific tile to use.
func _get_autotile_tile_to_use_at(tile_position, tile_id):
	var tile_to_use = tile_id
	
	var tile_name = get_tile_name(tile_id)
	var tile_group = get_tile_group(tile_name)
	
	# Water and Lava use custom autotiling rules
	if ["Lava1", "Water1"].has(tile_group):
		var tile = "Lava" if tile_group == "Lava1" else "Water"
		
		var above_tile = get_cellv(tile_position + Vector2.UP)
		var above_tile_name = get_tile_name(above_tile)
		var above_tile_group = get_tile_group(above_tile_name)
		
		var liquid_is_on_surface = !["Lava1", "Water1"].has(above_tile_group)
		
		if liquid_is_on_surface:
			var liquid_surface_tile_number = fmod(tile_position.x, 4) + 1
			tile_to_use = str(tile) + str(liquid_surface_tile_number)
		else:
			tile_to_use = tile + "Fill"
		
		tile_to_use = tile_set.find_tile_by_name(tile_to_use)
	
	return tile_to_use

# Returns the group of a specific tile, or NULL if it is not in a group.
# E.g.: "WaterFill" is a tile within the group "Water1".
# "Water1" is the main tile of a group, whilst "WaterFill" is a subtile.
func get_tile_group(tile_name):
	for group_name in group_tiles:
		var tiles_in_group = group_tiles.get(group_name)
		if tiles_in_group.has(tile_name): return group_name
	return null

func get_tile_name(tile_id):
	return tile_set.tile_get_name(tile_id)

func _update_solidity(new_value):
	#print("solid " + str(new_value))
	solid = new_value
	set_collision_layer_bit(0, new_value)
	set_collision_mask_bit(0, new_value)

func _update_liquid_collision(new_value):
	#print("liquid " + str(new_value))
	liquid = new_value
	set_collision_layer_bit(7, new_value)
	set_collision_mask_bit(7, new_value)

func _update_multiply_color(new_value):
	multiply_color = new_value
	modulate = multiply_color

func _update_overlay_color(new_value):
	overlay_color = new_value
	use_parent_material = false
	
	var overlay_plane = Plane(overlay_color.r, overlay_color.g, overlay_color.b, overlay_color.a)
	
	material.set_shader_param("overlay_color", overlay_plane)
	unique_material = true
