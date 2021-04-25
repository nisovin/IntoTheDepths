extends Area2D

signal hit

var dead = false
var velocity = Vector2.ZERO
var radius
var bounces

func init(pos, vel, rad):
	position = pos
	velocity = vel
	rotation = vel.angle()
	radius = rad
	
func bounce(b):
	bounces = b

func _physics_process(delta):
	if not dead:
		position += velocity * delta
		if position.y > 1200 or position.y < 0:
			dead = true
			queue_free()

func _on_Missile_area_entered(_area):
	if not dead:
		emit_signal("hit", global_position, velocity, bounces)
		dead = true
	queue_free()
		
