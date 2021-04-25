extends Node2D

const Chunk = preload("Chunk.tscn")

const VERT_ACCEL_RATE = 0.5
const VERT_DECEL_RATE = 2
const MOVE_SPEED = 200
const SIDE_ACCEL = 800
const EXPLOSION_RADIUS = 150
const SHIELD_EXPLOSION_RADIUS = 300
const MISSILE_SPEED = 800

onready var chunks = $Chunks
onready var player = $Player
onready var gui = $GUI

var texture = preload("res://av826a49819cd77dc3fdf.jpg")
var new_texture = preload("res://avbde5894a2df88067720.jpg")

var chunk_depth: int = 0
var player_depth: float = 0
var center: float = Game.CHUNK_WIDTH / 2
var width: float = Game.WIDTH_START
var width_change_dir = -1
var chunks_since_texture_change = 0
var chunks_since_power_up = 0
var powerup_counter = 0
var gold_parts = 0

var normal_fall_speed = Game.FALL_SPEED_START
var fall_speed = normal_fall_speed
var move_speed = 0

var player_dead = false
var slow_time = Game.slow_time
var missiles = Game.missiles
var shields = Game.shields
var gold_multiplier = Game.gold_multiplier + 1
var immunity = 0

func _ready():
	for i in 8:
		generate_chunk()

func _physics_process(delta):
	if player_dead: return
	
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
	move_speed = move_toward(move_speed, target_speed, accel * delta)
	player.position.x += move_speed * delta
	if player.position.x < 0 or player.position.x > Game.CHUNK_WIDTH:
		die()
	
	# fall speed
	if Input.is_action_pressed("slow") and slow_time > 0:
		fall_speed = move_toward(fall_speed, normal_fall_speed * 0.25, VERT_DECEL_RATE * normal_fall_speed * delta)
		slow_time -= delta
		if slow_time < 0: slow_time = 0
		gui.update_slow_time(slow_time, false)
	elif fall_speed < normal_fall_speed:
		fall_speed = move_toward(fall_speed, normal_fall_speed, VERT_ACCEL_RATE * normal_fall_speed * delta)
		
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
		
func _unhandled_input(event):
	if event.is_action_pressed("fire"):
		if missiles > 0:
			var vel = player.global_position.direction_to(get_global_mouse_position()) * MISSILE_SPEED
			missiles -= 1
			fire_missile(player.position, vel, Game.missile_bounces)
			gui.update_missiles(missiles)

func fire_missile(pos, vel, bounces):
	var missile = Game.Missile.instance()
	add_child(missile)
	missile.init(pos, vel, EXPLOSION_RADIUS)
	missile.bounce(bounces)
	missile.connect("hit", self, "missile_hit")

func missile_hit(pos, vel, bounces):
	explode(pos, EXPLOSION_RADIUS)
	if bounces > 0:
		vel.x *= -1
		bounces -= 1
		call_deferred("fire_missile", pos, vel, bounces)

func collect_powerup(type):
	match type:
		Game.PowerUpType.SLOW_TIME:
			slow_time = Game.slow_time + 1
			if slow_time > Game.slow_time + 1.25:
				slow_time = Game.slow_time + 1
			elif slow_time > Game.slow_time + 1:
				slow_time = Game.slow_time + 1
				fall_speed = 0
			gui.update_slow_time(slow_time, true)
		Game.PowerUpType.MISSILE:
			missiles += 1
			if missiles > Game.missiles + 1:
				missiles = Game.missiles + 1
				call_deferred("fire_missile", player.position, Vector2.DOWN * MISSILE_SPEED, 0)
			gui.update_missiles(missiles)
		Game.PowerUpType.SHIELD:
			shields += 1
			if shields > Game.shields + 1:
				shields = Game.shields + 1
				explode(player.position, 200)
			gui.update_shields(shields)
		Game.PowerUpType.GOLD_MULT:
			gold_multiplier += Game.gold_multiplier + 1
			gui.update_multiplier(gold_multiplier)

func explode(pos, radius):
	for chunk in chunks.get_children():
		if pos.y - radius < chunk.position.y + Game.CHUNK_HEIGHT and pos.y + radius > chunk.position.y:
			chunk.explode(pos, radius)
	var explosion = Game.Explosion.instance()
	chunks.get_children().back().add_child(explosion)
	explosion.init(pos, radius)
	

func generate_chunk():
	# handle width
	var next_width = width + Game.rng.randi_range(5, 20) * width_change_dir
	if Game.first_run and player_depth < 1000:
		next_width = width - Game.rng.randi_range(1, 8)
	if next_width < Game.WIDTH_MIN:
		next_width = Game.WIDTH_MIN
		width_change_dir = 1
	elif width_change_dir > 0 and next_width > Game.WIDTH_MAX:
		next_width = Game.WIDTH_MAX
		width_change_dir = -1
	elif width_change_dir > 0:
		if Game.rng.randf() < 0.1:
			width_change_dir = -1
		
	# create chunk
	var chunk = Chunk.instance()
	chunks.add_child(chunk)
	chunk.position = Vector2(Game.CHUNK_X_OFFSET, chunk_depth)
	chunk.init(center, width, next_width, chunk_depth, texture)
	if chunks_since_texture_change < 5 and new_texture != null:
		var chunk2 = chunk.duplicate()
		chunks.add_child(chunk2)
		chunk2.position = chunk.position
		chunk2.chunk_depth = chunk.chunk_depth
		chunk2.transition_layer(new_texture, chunks_since_texture_change / 5.0)
		chunks_since_texture_change += 1
		if chunks_since_texture_change == 5:
			texture = new_texture
			new_texture = null
		
	# update state
	center = chunk.last_center
	width = next_width
	chunk_depth += Game.CHUNK_HEIGHT
	
	# depth line
	if chunk_depth % (Game.PIXELS_PER_DEPTH_UNIT * 100) == 0:
		chunk.depth_line(chunk_depth / Game.PIXELS_PER_DEPTH_UNIT)
	
	# powerup
	chunks_since_power_up += 1
	var powerup_type = -1
	if Game.first_run:
		if chunks_since_power_up > 10 and powerup_counter <= 1:
			powerup_type = Game.PowerUpType.SLOW_TIME if powerup_counter == 0 else Game.PowerUpType.MISSILE
		elif chunks_since_power_up > 30:
			powerup_type = Game.PowerUpType.SLOW_TIME if Game.rng.randf() < 0.5 else Game.PowerUpType.MISSILE
	elif chunks_since_power_up > 20 and Game.rng.randf() < (chunks_since_power_up - 20) / 10.0:
		powerup_type = Game.rand_weighted(Game.powerups)
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
		explode(player.global_position, SHIELD_EXPLOSION_RADIUS)
		gui.update_shields(shields)
		gui.update_slow_time(slow_time, true)
	else:
		die()

func die():
	player_dead = true
	normal_fall_speed = 0
	fall_speed = 0
	explode(player.global_position, 50)
	player.queue_free()
	Game.last_depth = int(player_depth / Game.PIXELS_PER_DEPTH_UNIT)
	if Game.last_depth > Game.max_depth:
		Game.max_depth = Game.last_depth
	Game.first_run = false
	Game.save_game()
	yield(get_tree().create_timer(1.5), "timeout")
	get_tree().change_scene("res://Shop.tscn")
	

func _on_SpeedUpTimer_timeout():
	normal_fall_speed += 25
	if normal_fall_speed > Game.FALL_SPEED_MAX:
		$SpeedUpTimer.stop()