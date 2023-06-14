#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2022 Alexander Small <alexsmudgy20@gmail.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


extends TileMap
onready var level = get_parent()
onready var tile_ids = tile_set.get_tiles_ids()

export var enabled = true

# Some entites (i.e. Tux) should only be spawned once.
var one_only_entities = [
	"!!Tux"
]

var tile_entities = {
	# You! :D
	#"!!Tux" : "player/SpawnPoint",
	
	# End Goal Igloo
	"!EndGoalPosts" : "objects/EndGoalPosts",
	"!EndGoalIgloo" : "objects/EndGoalIgloo",
	
	"!Checkpoint" : "objects/Checkpoint",
	
	# Objects
	"ObjCoin" : "objects/Coin",
	
	"ObjBonusEmpty" : "objects/BonusEmpty",
	"ObjBonus1up" : "objects/Bonus1up",
	"ObjBonusCoin" : "objects/BonusCoin",
	"ObjBonusPowerup" : "objects/BonusBlock",
	"ObjBonusStar" : "objects/BonusStar",
	"ObjBonusInvisible" : "objects/BonusInvisible",
	
	"ObjBrick" : "objects/Brick",
	"ObjBrick1up" : "objects/Brick1up",
	"ObjBrickCoin" : "objects/BrickCoin",
	"ObjBrickPowerup" : "objects/BrickPowerup",
	"ObjBrickStar" : "objects/BrickStar",
	
	"ObjSBrick" : "objects/BrickSnow",
	"ObjSBrick1up" : "objects/Brick1upSnow",
	"ObjSBrickCoin" : "objects/BrickCoinSnow",
	"ObjSBrickPowerup" : "objects/BrickPowerupSnow",
	"ObjSBrickStar" : "objects/BrickStarSnow",
	
	# BadGuys (Enemies)
	"BadSnowball" : "enemies/Snowball",
	"BadBouncing" : "enemies/BouncingSnowball",
	"BadFlying" : "enemies/FlyingSnowball",
	"BadSpiky" : "enemies/Spiky",
	"BadIceblock" : "enemies/Iceblock",
	"BadBomb" : "enemies/Bomb",
	"BadJumpy" : "enemies/Jumpy",
	"BadStalactite" : "enemies/Stalactite",
	"BadFlame" : "enemies/FlameOrb",
	"BadIceDragon" : "enemies/IceDragon",
	"BadFish" : "enemies/Fish",
	"BadSmartball" : "enemies/Smartball",
	"BadSmartblock" : "enemies/Smartblock",
	
	"HazLavaHitbox" : "objects/LavaHitbox",
}

var entity_offset = Vector2(16, 16)

func _ready():
	set_spawn_point()

func set_spawn_point():
	for id in tile_ids:
		var tile_name = tile_set.tile_get_name(id)
		if tile_name == "!!Tux":
			var spawn = get_used_cells_by_id(id)
			
			if spawn.empty(): return
			spawn = spawn.front()
			
			owner.set("spawn_position", spawn)

func tiles_to_objects():
	if !enabled: return
	
	set_spawn_point()
	
	var once_only_entity_list = []
	
	# Iterate through all used Tile IDS
	for id in tile_ids:
		var tile_name = tile_set.tile_get_name(id)
		
		
		# If the tile has a corresponding entity
		if tile_entities.has(tile_name):
			
			# Load the entity
			var entity_scene = load("res://scenes/" + tile_entities.get(tile_name) + ".tscn")
			
			# Instance it for as many times as it's used
			for tile in get_used_cells_by_id(id):
				
				# Some entites (i.e. Tux) should only be spawned once.
				if once_only_entity_list.has(tile_name): continue
				elif one_only_entities.has(tile_name):
					once_only_entity_list.append(tile_name)
				
				var entity = entity_scene.instance()
				var entity_position = map_to_world(tile) + entity_offset + position
				
				# Rotate the objects based on their tile rotation / flipping.
				if "facing" in entity: # Handle this differently if it is an enemy (hence the facing variable)
					entity.facing = -1 if is_cell_x_flipped(tile.x, tile.y) else 1
				
				else:
					pass
#					if is_cell_transposed(tile.x, tile.y):
#						entity.rotation_degrees = 90
#						entity.scale.y = 1 if is_cell_x_flipped(tile.x, tile.y) else -1
#						entity.scale.x = -1 if is_cell_y_flipped(tile.x, tile.y) else 1
#					else:
#						entity.scale.x = -1 if is_cell_x_flipped(tile.x, tile.y) else 1
#						entity.scale.y = -1 if is_cell_y_flipped(tile.x, tile.y) else 1
				
				entity.set_position(entity_position)
				level.call_deferred("add_child", entity)
	
	queue_free()
