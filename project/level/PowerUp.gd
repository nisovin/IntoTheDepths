extends Area2D

signal collected

var powerup_type

func init(type):
	powerup_type = type
	$Visual.get_child(type).show()

func _process(delta):
	rotation += PI * 4 * delta

func _on_Powerup_area_entered(area):
	emit_signal("collected", powerup_type)
	queue_free()
