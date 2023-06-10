extends Node2D

onready var grumbel = $Grumbel
onready var anim_player = $AnimationPlayer
onready var statue = $Statue
onready var sfx = $SFX
onready var ambience = $Ambience
onready var evil_text = $EvilText/Control
onready var evil_text_label = $EvilText/Control/Label
onready var evil_text_static = $EvilText/Control/Static
onready var rng = RandomNumberGenerator.new()
onready var sanity_effect_animation = $SanityEffects

var evil_messages = [
	"USELESS",
	"REDUNDANT",
	"DEFECTIVE",
	"DEPRECATED",
	"DELETE",
	"DECOMPILE",
	"UNNECESSARY",
	"TRASH",
	"WORTHLESS",
	"LIFELESS",
	"NULL",
	"FATAL",
	"Tux.kill(true);",
	"SCRAP"
]

func _ready():
	grumbel.connect("fake_death", self, "phase_two_transition")
	grumbel.connect("phase_two", self, "phase_two")
	grumbel.connect("defeated", self, "defeated")
	grumbel.connect("dying", self, "dying")
	grumbel.connect("hurt", self, "hurt")
	
	yield(Global, "level_ready")
	
	if Scoreboard.number_of_deaths > 0 or grumbel.phase == 2 or grumbel.enabled:
		spawn_grumbel(0.1)
	else:
		statue_intro()

func spawn_grumbel(wait_time = 1):
	grumbel.enable(true, wait_time)
	statue.hide()
	yield(get_tree().create_timer(wait_time, false), "timeout")
	if grumbel.phase == 2:
		anim_player.play("phase_two")
	else: Music.play("Prophecy")

func statue_intro():
	yield(get_tree().create_timer(2, false), "timeout")
	
	sfx.play("Static")
	sfx.play("Glitch2")
	yield(call("evil_text_message", "UNNECESSARY", 2, Color(1,1,0), Color(1,1,1,0.1)), "completed")
	sfx.stop("Glitch2")
	sfx.stop("Static")
	
	yield(get_tree().create_timer(0.3, false), "timeout")
	
	sfx.play("Static")
	sfx.play("Glitch4")
	yield(call("evil_text_message", "USELESS", 0.05), "completed")
	sfx.stop("Glitch4")
	sfx.stop("Static")
	
	yield(get_tree().create_timer(0.3, false), "timeout")
	
	sfx.play("Static")
	sfx.play("Glitch3")
	yield(call("evil_text_message", "REDUNDANT", 0.05, Color(1,0.5,0), Color(1,0.5,0.5,0.2)), "completed")
	sfx.stop("Static")
	sfx.stop("Glitch3")
	yield(get_tree().create_timer(0.3, false), "timeout")
	
	sfx.play("Static")
	sfx.play("Glitch1")
	yield(call("evil_text_message", "WORTHLESS", 0.05, Color(1,1,1), Color(1,0,0,0.2)), "completed")
	sfx.stop("Static")
	sfx.stop("Glitch1")
	
	yield(get_tree().create_timer(0.6, false), "timeout")
	
	var timer = get_tree().create_timer(2, false)
	var shake = 0.05
	sfx.play("Rumbling")
	sfx.play("Rumbling2")
	while timer.time_left > 0:
		Global.camera_shake(shake * 2, 0.5)
		shake += 0.1
		statue.offset.x = sin(shake * shake) * shake
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	
	statue.offset.x = 0
	anim_player.play("flash_in")
	
	while anim_player.is_playing():
		Global.camera_shake(shake * 2, 0.5)
		shake += 1
		statue.offset.x = sin(shake * shake) * shake
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	
	sfx.play("Explosion")
	sfx.play("Explosion2")
	sfx.play("Explosion3")
	
	sfx.stop("Rumbling")
	sfx.stop("Rumbling2")
	
	yield(get_tree().create_timer(2, false), "timeout")
	
	spawn_grumbel(3)
	anim_player.play("flash_out")
	yield(anim_player, "animation_finished")
	
	yield(get_tree().create_timer(1, false), "timeout")
	
	if grumbel.state_machine.state == "waiting": 
		sfx.play("Glitch1")
		sfx.play("Static")
		yield(call("evil_text_message", "I WILL DEPRECATE YOU", 1, Color(1,0,0), Color(1,0,0,0.2)), "completed")
		sfx.stop("Glitch1")
		sfx.stop("Static")

func phase_two_transition():
	ambience.stop()
	anim_player.play("phase_two_transition")
	Music.pitch_slide_down()

func phase_two():
	anim_player.play("phase_two")
	Music.play("Prophecy", 30.6)
	Music.pitch_slide_up()
	grumbel_sanity_effect()

func defeated():
	sfx.stop_all()
	ambience.stop()
	pause_mode = Node.PAUSE_MODE_PROCESS
	anim_player.play("defeated")
	sanity_effect_animation.stop()
	sanity_effect_animation.play("stop")
	Global.can_pause = false

func hurt():
	sfx.stop_all()
	
	# When getting hit in phase 2, grumbel creates sanity effects if lower than half HP
	if grumbel.phase == 2:
		random_glitch_noise()
		
		if grumbel.health > grumbel.max_health_phase_two * 0.5:
			# Get a random evil message from the evil message array
			var message = rng.randi_range(0, evil_messages.size() - 1)
			message = evil_messages[message]
			
			var sound = "Glitch" + str(rng.randi_range(1,3))
			
			sfx.play("Static")
			sfx.play(sound)
			yield(call("evil_text_message", message, 0.05, Color(1,1,1), Color(1,0,0,0.1)), "completed")
			sfx.stop(sound)
			sfx.stop("Static")
		
		else:
			grumbel_sanity_effect()

func grumbel_sanity_effect():
	rng.randomize()
	
	var speed = rng.randf_range(0.25, 1)
	sfx.play("SanityEffect")
	
	sanity_effect_animation.stop()
	sanity_effect_animation.play("sanity_effect", -1, speed)
	yield(get_tree(), "idle_frame")
	
	
	yield(sanity_effect_animation, "animation_finished")

func random_glitch_noise():
	rng.randomize()
	var sound = "Glitch" + str(rng.randi_range(1,4))
	
	var sound_node = sfx.get_node(sound)
	sound_node.volume_db = rng.randf_range(3, -3)
	sound_node.pitch_scale = rng.randf_range(0.75, 3)
	
	sfx.play(sound)
	
	yield(get_tree().create_timer(rng.randf_range(0.25, 1)), "timeout")
	sfx.stop(sound)

func dying():
	Music.play("Prophecy", 19.5)
	Music.pitch_slide_up()
	
	anim_player.play("dying")
	yield(get_tree().create_timer(1), "timeout")
	yield(call("cry_out_in_despair", 0.3), "completed")
	yield(get_tree().create_timer(0.1), "timeout")
	yield(call("cry_out_in_despair", 0.1), "completed")
	yield(get_tree().create_timer(0.4), "timeout")
	yield(call("cry_out_in_despair", 0.1), "completed")
	yield(get_tree().create_timer(0.05), "timeout")
	
	var i = 20
	var time = 0.2
	var brightness = 0
	
	Music.pitch_slide_down()
	
	while(i > 0):
		i -= 1
		time *= 0.9
		brightness += 0.125
		yield(call("cry_out_in_despair", time, brightness), "completed")
		yield(get_tree().create_timer(time), "timeout")
	sfx.stop("Static")
	Music.stop_all()

# Grumbel says "NO" as he dies
func cry_out_in_despair(message_time : float, brightness = 0):
	evil_text.modulate.a = 1 - brightness * 0.5
	sfx.play("Static")
	yield(call("evil_text_message", "NO", message_time, Color(1,1,1,1), Color(brightness + 0.5,0,0,1 - brightness)), "completed")
	yield(get_tree(), "idle_frame")
	sfx.stop("Static")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "dying":
		Global.level_completed()

func evil_text_message(message_text : String, message_time : float, text_colour : Color = Color(1,1,0), static_color : Color = Color(1,1,1,0.2)):
	if get_tree().paused: return
	
	AudioServer.set_bus_mute(3, true)
	
	var p = pause_mode
	var can_pause = Global.can_pause
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().paused = true
	Global.can_pause = false
	
	evil_text_label.modulate = text_colour
	evil_text_static.modulate = static_color
	evil_text_label.text = message_text
	evil_text.show()
	
	yield(get_tree().create_timer(message_time), "timeout")
	
	evil_text.hide()
	
	pause_mode = p
	
	AudioServer.set_bus_mute(3, false)
	
	get_tree().paused = false
	Global.can_pause = can_pause
