extends Area2D

const MOVE_SPEED = 200
const SIDE_ACCEL = 800
const PLAYER_ROT = deg2rad(30)

onready var left_turn_thruster = $LeftTurnThruster
onready var right_turn_thruster = $RightTurnThruster
onready var left_slow_thruster = $LeftSlowThruster
onready var right_slow_thruster = $RightSlowThruster
onready var audio_slow = $AudioSlow
onready var left_rays = $LeftRays.get_children()
onready var right_rays = $RightRays.get_children()

var slow_thrusters_on = false
var move_speed = 0

func move(delta):
	var x = Input.get_action_strength("right") - Input.get_action_strength("left")
	if OS.has_feature("mobile"):
		x = Input.get_gravity().normalized().x
		if abs(x) < Settings.tilt_dead_zone / 100:
			x = 0
		else:
			x = move_toward(x, 0, Settings.tilt_dead_zone / 100)
			x = clamp(x * Settings.tilt_sensitivity / 10, -1, 1)
	var target_speed = MOVE_SPEED * x
	var accel = SIDE_ACCEL
	if x > 0:
		accel *= abs(x)
		if move_speed < 0:
			accel *= 2
	elif x < 0:
		accel *= abs(x)
		if move_speed > 0:
			accel *= 2
	move_speed = move_toward(move_speed, target_speed, accel * delta)
	position.x += move_speed * delta
	rotation = move_speed / MOVE_SPEED * PLAYER_ROT

func choose_missile_dirs():
	var dirs = [null, null]
	
	var closest_dist = -1
	var closest_point = null
	
	for ray in left_rays:
		ray.force_raycast_update()
		if ray.is_colliding():
			var dist = global_position.distance_squared_to(ray.get_collision_point())
			if closest_dist == -1 or dist < closest_dist:
				closest_dist = dist
				closest_point = ray.get_collision_point()
				
	if closest_point != null:
		dirs[0] = global_position.direction_to(closest_point)
	else:
		dirs[0] = Vector2(-1, 1).normalized()
		
	closest_dist = -1
	closest_point = null
	
	for ray in right_rays:
		ray.force_raycast_update()
		if ray.is_colliding():
			var dist = global_position.distance_squared_to(ray.get_collision_point())
			if closest_dist == -1 or dist < closest_dist:
				closest_dist = dist
				closest_point = ray.get_collision_point()
				
	if closest_point != null:
		dirs[1] = global_position.direction_to(closest_point)
	else:
		dirs[1] = Vector2(1, 1).normalized()
		
	return dirs

func move_thrusters(dir):
	if dir < 0:
		right_turn_thruster.emitting = true
		left_turn_thruster.emitting = false
	elif dir > 0:
		left_turn_thruster.emitting = true
		right_turn_thruster.emitting = false
	else:
		left_turn_thruster.emitting = false
		right_turn_thruster.emitting = false
		
func slow_thrusters(on):
	left_slow_thruster.emitting = on
	right_slow_thruster.emitting = on
	if on and not slow_thrusters_on:
		audio_slow.play()
	elif not on and slow_thrusters_on:
		audio_slow.stop()
	slow_thrusters_on = on

func shield(on):
	$Shield.visible = on
