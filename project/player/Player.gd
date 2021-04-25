extends Area2D

onready var left_turn_thruster = $LeftTurnThruster
onready var right_turn_thruster = $RightTurnThruster
onready var left_slow_thruster = $LeftSlowThruster
onready var right_slow_thruster = $RightSlowThruster
onready var audio_slow = $AudioSlow

var slow_thrusters_on = false

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
