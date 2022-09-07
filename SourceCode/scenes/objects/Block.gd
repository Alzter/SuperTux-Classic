#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2000 Bill Kendrick <bill@newbreedsoftware.com>
#  Copyright (C) 2004 Tobias Glaesser <tobi.web@gmx.de>
#  Copyright (C) 2004 Matthias Braun <matze@braunis.de>
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


extends StaticBody2D

export var type = ""
export var initial_animation = "default"
export var contains_powerup = false
export var contains_coin = false
export (PackedScene) var contents_small
export (PackedScene) var contents_big
onready var animation_player = $AnimationPlayer
onready var sprite = $AnimatedSprite
onready var sfx = $SFX
onready var collision_shapes = [$Hitbox, $AboveHitbox, $CollisionShape2D]
onready var above_hitbox = $AboveHitbox
onready var destroy_timer = $DestroyTimer

onready var initial_position = global_position

var velocity = Vector2()
var hit = false

func _ready():
	sprite.play(initial_animation)

func be_hit_from_above(body):
	if body.is_in_group("players"):
		var vel_x = 0 #body.velocity.x * 0.25
		var vel_y = -6 * Global.TILE_SIZE
		_get_hit(body, vel_x, vel_y)

func be_hit_from_side(vel, body):
	var vel_x = vel.x * 0.5 if hit else 0
	var vel_y = 0
	_get_hit(body, vel_x, vel_y)

func _get_hit(body, vel_x = 0, vel_y = 0):
	velocity = Vector2(vel_x, vel_y)
	sfx.play("Brick")
	if !hit: _kill_enemies()
	
	if !hit:
		if contains_powerup:
			var small = is_body_small(body, true)
			_spawn_contents(body, small)
			_make_box_empty()
		else:
			if contains_coin:
				_get_coin()
			elif type == "Brick":
				var small = is_body_small(body, false)
				if !small: _brick_smash()
			else: _make_box_empty()

func _get_coin():
	sfx.play("Coin")
	animation_player.play("coin")
	_make_box_empty()
	Scoreboard.coins += 1

func _make_box_empty():
	sprite.play("Empty")
	hit = true

func _brick_smash():
	_disable_collision()
	sfx.play("Smash")
	destroy_timer.start()
	animation_player.play("smash")

func _process(delta):
	global_position += velocity * delta
	velocity *= 0.8
	global_position.x = lerp(global_position.x, initial_position.x, 0.1)
	global_position.y = lerp(global_position.y, initial_position.y, 0.1)

# Returns true if small tux hit this box
func is_body_small(body, default = true):
	if body.is_in_group("players"):
		return body.state == body.states.SMALL
	else: return default

func _spawn_contents(body, small = true):
	sfx.play("Bonus")
	var facing = 1
	if body != null:
		facing = sign(global_position.x - body.global_position.x)
		if facing == 0: facing = 1
	
	var pos = global_position - Vector2(0, Global.TILE_SIZE)
	var object_to_spawn = contents_small if small else contents_big
	var o = object_to_spawn.instance()
	Global.current_scene.add_child(o)
	o.global_position = pos
	o.facing = facing

func _kill_enemies():
	for body in above_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("die"):
				body.die(true)
	
	for area in above_hitbox.get_overlapping_areas():
		if area.is_in_group("coins"):
			if area.has_method("collect"):
				area.collect()

func _disable_collision():
	for hitbox in collision_shapes:
		hitbox.call_deferred("queue_free")

func _on_DestroyTimer_timeout():
	call_deferred("queue_free")
