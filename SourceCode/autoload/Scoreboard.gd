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


extends CanvasLayer
# This node keeps track of all player variables which persist between levels,
# such as the coin counter, lives, etc.

# It also acts as the HUD to display the coins and lives counter in levels.

export var initial_coins = 0
export var initial_lives = 3
export var initial_state = 0
export var game_over_lives = 10 # How many lives we grant the player after getting a game over.

onready var coins = initial_coins setget _set_coin_count
onready var lives : int = initial_lives setget _set_lives_count
onready var player_initial_state = initial_state # What powerup state Tux has when spawning into the level.

onready var level_timer = $LEVELTIMER
onready var hud_node = $Control
onready var tween = $Tween
onready var coins_text = $Control/CoinCounter/Coins
onready var lives_counter = $Control/LifeCounter
onready var lives_text = $Control/LifeCounter/Lives
onready var timer_ui = $Control/ClockCounter
onready var timer_text = $Control/ClockCounter/Timer
onready var game_over_screen = $Control/GameOverScreen
onready var sfx = $SFX
onready var message_text_object = $Message

var number_of_deaths = 0
var level_timer_enabled = false
var tick_time = 999
var message_text = "" setget update_message_text

var score_visible = true

func _ready():
	self.message_text = ""
	stop_level_timer()

func _process(delta):
	_draw()
	
	if level_timer_enabled:
		
		# If we have under 10 seconds remaining in the current level:
		if level_timer.time_left < 10:
			# Play a clock ticking noise every second
			var time_left = ceil(level_timer.time_left)
			
			if time_left < tick_time:
				
				tick_time = time_left
				
				if time_left == 0:
					sfx.play("TimeOver")
				else:
					sfx.play("Tick")

func _draw():
	if level_timer_enabled:
		var time_left = ceil(level_timer.time_left)
		timer_text.text = str(time_left)
	
	coins_text.text = str(coins)
	
	lives_text.text = str( max(lives, 0) )

func start_level_timer():
	level_timer.paused = false

func stop_level_timer():
	level_timer.paused = true

func enable_level_timer(time):
	tick_time = 999
	level_timer_enabled = true
	level_timer.paused = true
	level_timer.start(time)
	timer_ui.show()

func disable_level_timer():
	stop_level_timer()
	level_timer_enabled = false
	timer_ui.hide()

func set_level_timer(time):
	tick_time = 999
	level_timer_enabled = true
	level_timer.paused = false
	level_timer.start(time)
	timer_ui.show()

func _set_coin_count(new_value):
	coins = new_value
	if coins >= 100:
		coins = 0
		self.lives += 1

func _set_lives_count(new_value):
	if new_value > lives: sfx.play("1up")
	lives = clamp(new_value, -1, 99)

func hide():
	score_visible = false
	clear_message()
	hud_node.hide()

func show(include_lives_count = true):
	score_visible = true
	lives_counter.visible = include_lives_count
	hud_node.show()

func reset_player_values(game_over = false, reset_state = true):
	coins = initial_coins
	lives = game_over_lives if game_over else initial_lives
	if reset_state: player_initial_state = initial_state

func game_over():
	stop_level_timer()
	
	# We need the music node to process so it can play the game over song
	# even while the world is paused.
	Music.pause_mode = PAUSE_MODE_PROCESS
	
	# Pause the game so that wild shennanigans don't occur
	# while the game over screen is happening
	get_tree().paused = true
	
	# Make the game over screen appear
	game_over_screen.appear()
	Music.play("GameOver")
	
	# Wait five seconds
	yield(get_tree().create_timer(4.5), "timeout")
	
	game_over_screen.hide_text()
	
	# ============================================================
	# Move the lives counter to the center of the screen,
	# and make the "Game Over" text fade out
	var shrink = ResolutionManager.screen_shrink
	var screen_center = get_viewport().size * 0.5 / shrink
	screen_center += Vector2(-50, 30) / shrink
	
	tween.interpolate_property(lives_counter,
	"rect_position",
	lives_counter.rect_position,
	screen_center,
	0.75,
	Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	tween.start()
	
	yield(tween, "tween_completed")
	yield(get_tree().create_timer(0.5), "timeout")
	
	# ============================================================
	# Then, make the life value increase to 10
	# while playing the 1up sound effect
	sfx.play("1up")
	tween.interpolate_property(self, "lives", 0, game_over_lives,
	0.5,
	Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()
	
	yield(tween, "tween_completed")
	yield(get_tree().create_timer(1), "timeout")
	
	# ============================================================
	# We are now done playing the "Game Over" animation and
	# refilling the players lives, so we can now reload the current level
	
	# Reset the player's coin count, current state, etc.
	# When we game over we want a blank slate to start the game on!
	reset_player_values(true)
	
	# Hide the game over UI
	game_over_screen.hide()
	
	# Reset the position of the life counter to the bottom right
	shrink = ResolutionManager.screen_shrink
	lives_counter.rect_position = Vector2(0, get_viewport().size.y / shrink)
	
	# Remove the player's checkpoint progress and reload the current level.
	Global.spawn_position = null
	Global.respawn_player()
	
func _on_LEVELTIMER_timeout():
	if Global.player == null: return
	var player_state = Global.player.state_machine.state
	if !["win", "dead"].has(player_state):
		Global.player.die()

func update_message_text(new_value):
	message_text = new_value
	if message_text == "" or message_text == null:
		message_text_object.hide()
	else:
		message_text_object.show()
		message_text_object.bbcode_text = "[center][wave]" + "\n" + new_value

func display_message(message_text):
	update_message_text(message_text)

func clear_message():
	update_message_text("")
