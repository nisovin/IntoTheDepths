extends Node2D

const Chunk = preload("Chunk.tscn")

const VERT_ACCEL_RATE = 0.5
const VERT_DECEL_RATE = 2
const MOVE_SPEED = 200
const SIDE_ACCEL = 800
const PLAYER_ROT = deg2rad(30)
const EXPLOSION_RADIUS = 150
const SHIELD_EXPLOSION_RADIUS = 300
const MISSILE_SPEED = 800

const TEXTURES = [
	[0, preload("dirt.png"), Color(.2, .1, 0)],
	[250, preload("stone1.png"), Color(.25, .25, .3)],
	[750, preload("magma.png"), Color(.3, .1, .1)],
	[1500, preload("purple.png"), Color("#5D3660")],
	[3000, preload("digital.png"), Color("#2C5B34")]
]

onready var chunks = $Chunks
onready var player = $Player
onready var gui = $GUI
onready var back_color = $Backdrop/ColorRect

var countdown = 4
var texture = TEXTURES[0][1]
var new_texture = null
var next_texture = 1

var chunk_depth: int = 0
var player_depth: float = 0
var center: float = Game.CHUNK_WIDTH / 2
var width: float = Game.WIDTH_START if Game.first_run else Game.WIDTH_MAX
var width_change_dir = -1
var chunks_since_texture_change = 0
var chunks_since_power_up = 0
var chunks_since_gold_powerup = 0
var powerup_counter = 0

var normal_fall_speed = Game.FALL_SPEED_START
var fall_speed = normal_fall_speed
var move_speed = 0
var time_since_mouse_move = 0

var player_dead = false
var slow_time = Game.slow_time
var missiles = Game.missiles
var shields = Game.shields
var gold_multiplier = Game.gold_multiplier + 1
var immunity = 0

func _ready():
	if Game.skip > 0:
		chunk_depth = Game.skip * Game.PIXELS_PER_DEPTH_UNIT
		player_depth = Game.skip * Game.PIXELS_PER_DEPTH_UNIT
		gui.update_depth(Game.skip)
		for t in TEXTURES:
			if t[0] < Game.skip:
				texture = t[1]
				back_color.color = t[2]
		Game.skip = 0
	for i in 8:
		generate_chunk()
	player.shield(shields > 0)
	Game.play_music()

func _on_CountdownTimer_timeout():
	countdown -= 1
	gui.show_countdown(countdown)
	if countdown == 0:
		$CountdownTimer.stop()
		Game.play_audio("boop2")
		if Game.first_run:
			gui.show_hint("Use A and D\nor arrow keys to move")
	else:
		Game.play_audio("boop1")

func _physics_process(delta):
	if countdown > 0 or player_dead: return
	
	# move player
	var x = Input.get_action_strength("right") - Input.get_action_strength("left")
	var target_speed = 0
	var accel = SIDE_ACCEL
	if x > 0:
		target_speed = MOVE_SPEED
		if move_speed < 0:
			accel *= 2
	elif x < 0:
		target_speed = -MOVE_SPEED
		if move_speed > 0:
			accel *= 2
	player.move_thrusters(x)
	move_speed = move_toward(move_speed, target_speed, accel * delta)
	player.position.x += move_speed * delta
	player.rotation = move_speed / MOVE_SPEED * PLAYER_ROT
	if player.position.x < 0 or player.position.x > Game.CHUNK_WIDTH:
		die()
	
	# fall speed
	if Input.is_action_pressed("slow") and slow_time > 0:
		fall_speed = move_toward(fall_speed, normal_fall_speed * 0.25, VERT_DECEL_RATE * normal_fall_speed * delta)
		slow_time -= delta
		if slow_time < 0: slow_time = 0
		gui.update_slow_time(slow_time, false)
		player.slow_thrusters(true)
	elif fall_speed < normal_fall_speed:
		fall_speed = move_toward(fall_speed, normal_fall_speed, VERT_ACCEL_RATE * normal_fall_speed * delta)
		player.slow_thrusters(false)
	else:
		player.slow_thrusters(false)
		
	# move chunks up
	player_depth += fall_speed * delta
	var first = chunks.get_child(0)
	var y = first.position.y - fall_speed * delta
	for c in chunks.get_children():
		if c.trans:
			y -= Game.CHUNK_HEIGHT
		c.position.y = y
		y += Game.CHUNK_HEIGHT
		
	# destroy
	if first.position.y + Game.CHUNK_HEIGHT < -200:
		first.queue_free()
		var second = chunks.get_child(1)
		if second.trans:
			second.queue_free()

	# generate
	if y < get_viewport().size.y + 500:
		generate_chunk()
	
	# immunity
	if immunity > 0:
		immunity -= delta
		if immunity <= 0:
			var walls = player.get_overlapping_areas()
			if walls.size() > 0:
				_on_Player_area_entered(walls[0])
	
	# stats
	Game.gold += fall_speed * delta * gold_multiplier / Game.PIXELS_PER_DEPTH_UNIT
	gui.update_depth(player_depth / Game.PIXELS_PER_DEPTH_UNIT)
	time_since_mouse_move += delta
		
func _unhandled_input(event):
	if countdown > 0 or player_dead: return
	if event.is_action_pressed("fire"):
		if missiles > 0:
#			var dir = Vector2.DOWN
#			if Game.using_controller:
#				var x = Input.get_joy_axis(Game.device, JOY_AXIS_0)
#				if abs(x) < 0.15:
#					dir = Vector2.DOWN
#				else:
#					dir = Vector2(x, 1).normalized()
#			elif time_since_mouse_move < 10:
#				dir = player.global_position.direction_to(get_global_mouse_position())
#			else:
#				dir = Vector2.DOWN
			#for dir in player.choose_missile_dirs():
			#	fire_missile(player.position, dir * MISSILE_SPEED, Game.missile_bounces, false)
			fire_missile(player.position, Vector2(-1, 2).normalized() * MISSILE_SPEED, Game.missile_bounces, false)
			fire_missile(player.position, Vector2(1, 2).normalized() * MISSILE_SPEED, Game.missile_bounces, false)
			missiles -= 1
			gui.update_missiles(missiles)
			
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.5):
		Game.using_controller = true
		Game.device = event.device
	elif event is InputEventMouseButton or event is InputEventKey:
		Game.using_controller = false
	elif event is InputEventMouseMotion:
		time_since_mouse_move = 0

func fire_missile(pos, vel, bounces, is_bounce):
	var missile = Game.Missile.instance()
	add_child(missile)
	missile.init(pos, vel, EXPLOSION_RADIUS)
	missile.bounce(bounces)
	missile.connect("hit", self, "missile_hit")
	if not is_bounce:
		Game.play_audio("fire")

func missile_hit(pos, vel, bounces):
	explode(pos, EXPLOSION_RADIUS, Color.orangered, Color.orange)
	if bounces > 0:
		vel.x *= -1
		bounces -= 1
		call_deferred("fire_missile", pos, vel, bounces, true)

func collect_powerup(type):
	match type:
		Game.PowerUpType.SLOW_TIME:
			slow_time += 1
			if slow_time > Game.slow_time + 1.75:
				slow_time = Game.slow_time + 1
				fall_speed = 0
			elif slow_time > Game.slow_time + 1:
				slow_time = Game.slow_time + 1
			gui.update_slow_time(slow_time, true)
			if Game.first_run and not Game.collected_slow:
				gui.show_hint("Hold Z to fire thrusters")
				Game.collected_slow = true
			Game.play_audio("powerup_slow")
		Game.PowerUpType.MISSILE:
			missiles += 1
			if missiles > Game.missiles + 1:
				missiles = Game.missiles + 1
				call_deferred("fire_missile", player.position, Vector2.DOWN * MISSILE_SPEED, 0, false)
			gui.update_missiles(missiles)
			if Game.first_run and not Game.collected_missile:
				gui.show_hint("Press C to launch missiles")
				Game.collected_missile = true
			Game.play_audio("powerup_missile")
		Game.PowerUpType.SHIELD:
			shields += 1
			if shields > Game.shields + 1:
				shields = Game.shields + 1
				explode(player.position, 200, Color.darkcyan, Color.darkslategray)
			gui.update_shields(shields)
			player.shield(shields > 0)
			Game.play_audio("powerup_shield")
		Game.PowerUpType.GOLD_MULT:
			gold_multiplier += Game.gold_multiplier + 1
			gui.update_multiplier(gold_multiplier)
			Game.play_audio("powerup_gold")

func explode(pos, radius, color1, color2):
	for chunk in chunks.get_children():
		if pos.y - radius < chunk.position.y + Game.CHUNK_HEIGHT and pos.y + radius > chunk.position.y:
			chunk.explode(pos, radius)
	var explosion = Game.Explosion.instance()
	chunks.get_children().back().add_child(explosion)
	explosion.init(pos, radius, color1, color2)
	Game.play_audio("explode")

func generate_chunk():
	# handle width
	var next_width = width + Game.rng.randi_range(5, 20) * width_change_dir
	if Game.first_run and player_depth < 1000:
		next_width = width - Game.rng.randi_range(1, 8)
	var min_width = Game.WIDTH_MIN
	if chunk_depth > Game.PIXELS_PER_DEPTH_UNIT * 1500:
		min_width -= 15
	if chunk_depth > Game.PIXELS_PER_DEPTH_UNIT * 3000:
		min_width -= 10
	if chunk_depth > Game.PIXELS_PER_DEPTH_UNIT * 5000:
		min_width -= 10
	if next_width < min_width:
		next_width = min_width
		width_change_dir = 1
	elif width_change_dir > 0 and next_width > Game.WIDTH_MAX:
		next_width = Game.WIDTH_MAX
		width_change_dir = -1
	elif width_change_dir > 0:
		if Game.rng.randf() < 0.1:
			width_change_dir = -1
		
	# get y pos
	var y = 0
	if chunks.get_child_count() > 0:
		y = chunks.get_children().back().position.y + Game.CHUNK_HEIGHT
		
	# create chunk
	var chunk = Chunk.instance()
	chunks.add_child(chunk)
	chunk.position = Vector2(Game.CHUNK_X_OFFSET, y)
	chunk.init(center, width, next_width, chunk_depth, texture)
	if chunks_since_texture_change < Game.TRANSITION_CHUNKS and new_texture != null:
		var chunk2 = chunk.duplicate()
		chunks.add_child(chunk2)
		chunk2.position = chunk.position
		chunk2.chunk_depth = chunk.chunk_depth
		chunk2.transition_layer(new_texture, chunks_since_texture_change / float(Game.TRANSITION_CHUNKS))
		chunks_since_texture_change += 1
		if chunks_since_texture_change == Game.TRANSITION_CHUNKS:
			texture = new_texture
			new_texture = null
		
	# update state
	center = chunk.last_center
	width = next_width
	chunk_depth += Game.CHUNK_HEIGHT
	
	# depth line
	if chunk_depth % (Game.PIXELS_PER_DEPTH_UNIT * 100) == 0:
		chunk.depth_line(chunk_depth / Game.PIXELS_PER_DEPTH_UNIT)
	
	# texture
	if next_texture < TEXTURES.size() and chunk_depth / Game.PIXELS_PER_DEPTH_UNIT >= TEXTURES[next_texture][0]:
		new_texture = TEXTURES[next_texture][1]
		var new_color = TEXTURES[next_texture][2]
		$Backdrop/Tween.remove_all()
		$Backdrop/Tween.interpolate_property($Backdrop/ColorRect, "color", $Backdrop/ColorRect.color, new_color, Game.TRANSITION_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN, 5)
		$Backdrop/Tween.start()
		next_texture += 1
		chunks_since_texture_change = 0
	
	# powerup
	chunks_since_power_up += 1
	chunks_since_gold_powerup += 1
	var powerup_type = -1
	if Game.first_run:
		if chunks_since_power_up > 10 and powerup_counter <= 1:
			powerup_type = Game.PowerUpType.SLOW_TIME if powerup_counter == 0 else Game.PowerUpType.MISSILE
		elif chunks_since_power_up > 30:
			powerup_type = Game.PowerUpType.SLOW_TIME if Game.rng.randf() < 0.5 else Game.PowerUpType.MISSILE
	elif chunks_since_power_up > 20 and Game.rng.randf() < (chunks_since_power_up - 20) / 10.0:
		var options = Game.powerups.duplicate()
		if chunk_depth > 1000 * Game.PIXELS_PER_DEPTH_UNIT and chunks_since_gold_powerup > 100:
			options[Game.PowerUpType.GOLD_MULT] += 10 + (chunks_since_gold_powerup - 100) / 10
		print(chunks_since_gold_powerup, options)
		powerup_type = Game.rand_weighted(options)
		if powerup_type == Game.PowerUpType.GOLD_MULT:
			print("got it")
			chunks_since_gold_powerup = 0
	if powerup_type >= 0:
		var powerup = Game.PowerUp.instance()
		chunk.add_child(powerup)
		powerup.init(powerup_type)
		powerup.position = Vector2(center + Game.rng.randf_range(-width / 6, width / 6), Game.CHUNK_HEIGHT)
		powerup.connect("collected", self, "collect_powerup")
		chunks_since_power_up = 0
		powerup_counter += 1

func _on_Player_area_entered(area):
	if not area.is_in_group("walls") or immunity > 0: return
	if shields > 0:
		shields -= 1
		fall_speed = 0
		immunity = 0.25
		slow_time = min(slow_time + 0.5, Game.slow_time + 1)
		explode(player.global_position, SHIELD_EXPLOSION_RADIUS, Color.cyan, Color.dodgerblue)
		gui.update_shields(shields)
		gui.update_slow_time(slow_time, true)
		player.shield(shields > 0)
	else:
		die()

func die():
	player_dead = true
	normal_fall_speed = 0
	fall_speed = 0
	explode(player.global_position, 50, Color.purple, Color.darkslateblue)
	player.queue_free()
	Game.last_depth = int(player_depth / Game.PIXELS_PER_DEPTH_UNIT)
	if Game.last_depth > Game.max_depth:
		Game.max_depth = Game.last_depth
	Game.last_texture = texture
	Game.first_run = false
	Game.save_game()
	yield(get_tree().create_timer(1.5), "timeout")
	get_tree().change_scene("res://main/Shop.tscn")
	

func _on_SpeedUpTimer_timeout():
	normal_fall_speed = floor(Game.FALL_SPEED_START + player_depth / Game.PIXELS_PER_DEPTH_UNIT * 0.75)
	if normal_fall_speed > Game.FALL_SPEED_MAX:
		normal_fall_speed = Game.FALL_SPEED_MAX
		$SpeedUpTimer.stop()

