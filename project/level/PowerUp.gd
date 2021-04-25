extends Area2D

signal collected

var powerup_type
var rot_speed = PI * 2

func init(type):
	powerup_type = type
	$Visual.get_child(type).show()
	if type == Game.PowerUpType.SLOW_TIME:
		rot_speed = PI * 4
	elif type == Game.PowerUpType.SHIELD:
		rot_speed = -PI

func _process(delta):
	rotation += rot_speed * delta

func _on_Powerup_area_entered(area):
	emit_signal("collected", powerup_type)
	queue_free()
