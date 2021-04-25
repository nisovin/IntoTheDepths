extends CPUParticles2D

func init(pos, radius):
	global_position = pos
	initial_velocity = radius * (1 / lifetime)
	emitting = true
