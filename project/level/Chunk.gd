extends Node2D

const OUTLINE_WIDTH = 6

onready var polygons = $Polygons
onready var area = $Area
onready var outlines = $Outlines

var polygon_nodes = []
var last_center
var chunk_depth
var trans = false
	
func init(start_center: int, from_width: float, to_width: float, depth: int, tex: Texture):
	var left_poly = []
	var right_poly = []
	last_center = start_center
	chunk_depth = depth
	var centers = [start_center]
	var widths = [from_width + Game.noise_1d(depth) * Game.WIDTH_NOISE_VARIANCE]
	var steps = Game.CHUNK_HEIGHT / Game.CHANGE_INTERVAL
	var margin = Game.CHUNK_MARGINS + to_width / 2
	for x in steps:
		last_center = clamp(last_center + Game.rng.randi_range(-Game.CENTER_CHANGE_VARIANCE, Game.CENTER_CHANGE_VARIANCE), margin, Game.CHUNK_WIDTH - margin)
		centers.append(last_center)
		widths.append(lerp(from_width, to_width, (x+1)/steps) + Game.noise_1d(depth + (x+1) * Game.CHANGE_INTERVAL) * Game.WIDTH_NOISE_VARIANCE)
	
	for i in centers.size():
		var left = Vector2(max(centers[i] - widths[i] / 2, Game.CHUNK_MARGINS), Game.CHANGE_INTERVAL * i)
		left_poly.append(left)
		var right = Vector2(min(centers[i] + widths[i] / 2, Game.CHUNK_WIDTH - Game.CHUNK_MARGINS), Game.CHANGE_INTERVAL * i)
		right_poly.append(right)
	left_poly.append(Vector2(0, Game.CHUNK_HEIGHT))
	left_poly.append(Vector2(0, 0))
	right_poly.invert()
	right_poly.append(Vector2(Game.CHUNK_WIDTH, 0))
	right_poly.append(Vector2(Game.CHUNK_WIDTH, Game.CHUNK_HEIGHT))
	
	left_poly = PoolVector2Array(left_poly)
	right_poly = PoolVector2Array(right_poly)
	
	$Area/Left.polygon = left_poly
	$Area/Right.polygon = right_poly
	$Polygons/LeftPolygon.texture = tex
	$Polygons/LeftPolygon.polygon = left_poly
	$Polygons/RightPolygon.polygon = right_poly
	$Polygons/RightPolygon.texture = tex
	setup_uv()
	setup_outlines()

func transition_layer(tex, pct):
	area.queue_free()
	trans = true
	$Polygons/LeftPolygon.texture = tex
	$Polygons/RightPolygon.texture = tex
	$Polygons.modulate = Color(1, 1, 1, pct)
	
func depth_line(depth):
	$Line2D/Label.text = str(depth)
	$Line2D.position.y = Game.CHUNK_HEIGHT + 150
	$Line2D.show()
	
func setup_uv():
	var tex_offset = wrapi(chunk_depth, 0, 1000)
	for p in polygons.get_child_count():
		var node = polygons.get_child(p)
		var uv = node.polygon
		for i in uv.size():
			uv[i] = uv[i] + Vector2(0, tex_offset)
		node.uv = uv

func setup_outlines():
	for node in outlines.get_children():
		node.queue_free()
	for node in polygons.get_children():
		if node.is_queued_for_deletion():
			continue
		var line_points_1 = []
		var line_points_2 = []
		var side = 0
		var use_2 = false
		for p in node.polygon:
			if p.x < 1:
				if side == 1:
					side = 0
					break
				side = -1
				use_2 = true
				if line_points_2.size() > 0:
					break
			elif p.x > Game.CHUNK_WIDTH - 1:
				if side == -1:
					side = 0
					break
				side = 1
				use_2 = true
				if line_points_2.size() > 0:
					break
			elif use_2:
				line_points_2.append(p)
			else:
				line_points_1.append(p)
		if side != 0:
			var line_points = line_points_2 + line_points_1
			for i in line_points.size():
				line_points[i].x += OUTLINE_WIDTH / 2 * side
			var line = Line2D.new()
			line.default_color = Color.black
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			line.width = OUTLINE_WIDTH + 2
			line.points = line_points
			outlines.add_child(line)
		

func explode(center_global, radius, precision = 8):
	# create subtraction polygon
	var poly_subtract = PoolVector2Array()
	var center = to_local(center_global)
	for i in precision:
		poly_subtract.push_back(center + Vector2.RIGHT.rotated(2 * PI / precision * i) * radius)
		
	# remove from existing polygons
	for p in polygons.get_child_count():
		var node = polygons.get_child(p)
		var poly = node.polygon
		var new_polys = Geometry.clip_polygons_2d(poly, poly_subtract)
		if new_polys.size() == 0:
			# completely destroyed
			node.queue_free()
			if not trans:
				area.get_child(p).queue_free()
		else:
			# normal
			var new_poly = new_polys.pop_front()
			node.polygon = new_poly
			if not trans:
				area.get_child(p).set_deferred("polygon", new_poly)
			# split
			while new_polys.size() > 0:
				new_poly = new_polys.pop_front()
				var new_poly_node = Polygon2D.new()
				new_poly_node.polygon = new_poly
				new_poly_node.texture = node.texture
				polygons.add_child(new_poly_node)
				var new_collision_node = CollisionPolygon2D.new()
				new_collision_node.polygon = new_poly
				if not trans:
					area.call_deferred("add_child", new_collision_node)
	
	# done
	setup_uv()
	setup_outlines()
