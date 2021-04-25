extends CPUParticles2D

func init(pos, radius, color1, color2):
	global_position = pos
	initial_velocity = radius * (1 / lifetime)
	color_ramp.colors[0] = color1
	color_ramp.colors[1] = color2
	color_ramp.colors[2] = color2
	color_ramp.colors[2].a = 0
	emitting = true
