class_name CellVisuals

func update_nucleus_shape(cell: Node2D):
	var n_pts = []
	for i in range(12):
		var a = (PI * 2 / 12) * i
		n_pts.append(Vector2(cos(a), sin(a)) * 18.0)
	cell.nucleus.polygon = n_pts

func update_membrane(cell: Node2D, time:  float, delta: float):
	# This is now in CellPhysics. update_membrane()
	pass

func update_nucleus_visuals(cell: Node2D, delta: float, time:  float):
	var n_scale = cell.nucleus_size / 18.0
	cell.nucleus. scale = cell.nucleus. scale.lerp(Vector2.ONE * n_scale, delta * 2.0)
	
	var n_offset = (cell.target_pos - cell.global_position).limit_length(cell.current_radius * 0.3)
	cell.nucleus.position = cell.nucleus.position.lerp(n_offset, delta * 2.0)
	
	# Being eaten - red glow
	if cell. is_being_eaten and is_instance_valid(cell.being_eaten_by):
		var pulse = sin(time * 20.0)  # Fast pulsing when eaten
		var eaten_color = Color(2.0, 0.0, 0.0).lerp(Color(3.0, 0.0, 0.0), (pulse + 1.0) * 0.5)
		cell.nucleus.modulate = eaten_color
		return
	
	# Energy-based color
	var energy_ratio = clamp(cell.energy / 100.0, 0.0, 1.0)
	var starving_color = Color(2, 0, 0)
	var healthy_color = Color(0, 2, 0)
	var base_color = starving_color. lerp(healthy_color, energy_ratio)
	
	if cell.energy >= cell.full_threshold:
		var pulse = (sin(time * 8.0) + 1.0) * 0.5
		var ready_color = Color(3.0, 3.0, 5.0)
		cell.nucleus.modulate = base_color.lerp(ready_color, pulse * 0.5)
	else:
		cell.nucleus.modulate = base_color

func draw(cell: Node2D, time: float = 0.0):

	# 1. NUCLEUS (jelly lag)
	var nucleus_offset = (cell.external_force * -0.05).limit_length(10.0)
	cell.draw_circle(
		nucleus_offset,
		cell.current_radius * 0.3,
		Color(0, 0, 0, 0.2)
	)
	cell.draw_circle(
		nucleus_offset,
		cell.current_radius * 0.25,
		cell.modulate.darkened(0.4)
	)

	# 2. INTERNAL ORGANELLES
	for i in range(3):
		var pos = Vector2(cos(i * 2.0), sin(i * 2.0)) * (cell.current_radius * 0.5)
		cell.draw_circle(
			pos + (cell.external_force * -0.02),
			2.0,
			Color(1, 1, 1, 0.3)
		)

	# 3. RIM LIGHTING
	var points := PackedVector2Array()
	for i in range(8):
		var a = PI * 1.1 + (i * 0.15)
		points.append(Vector2(cos(a), sin(a)) * (cell.current_radius * 0.85))

	cell.draw_polyline(points, Color(1, 1, 1, 0.5), 3.0)

	# BEING EATEN - RED GLOW & SUCTION
	if cell.is_being_eaten and is_instance_valid(cell.being_eaten_by):
		var eaten_pulse = sin(time * 15.0) * 0.5 + 0.5
		cell.draw_circle(Vector2.ZERO, cell.current_radius, Color(2.0, 0.0, 0.0, eaten_pulse * 0.5))
		
		# Draw suction lines being pulled in
		var suction_count = int(cell.eaten_amount * 16.0)
		for i in range(suction_count):
			var angle = (PI * 2 / 16.0) * i
			var p1 = Vector2(cos(angle), sin(angle)) * cell.current_radius
			var p2 = Vector2(cos(angle), sin(angle)) * (cell.current_radius * 0.4)
			cell.draw_line(p1, p2, Color(3.0, 0.0, 0.0, 0.8), 4.0)
		
		print("BEING EATEN: ", cell.eaten_amount * 100, "%")
		return
	
	# 1.  Carnivore - Spikes
	if cell.current_role == 5:  # CARNIVORE
		cell.modulate = Color(2.5, 0.1, 0.1)
		for i in range(12):
			var angle = (PI * 2 / 12) * i
			var p1 = Vector2(cos(angle), sin(angle)) * cell.current_radius
			var p2 = Vector2(cos(angle), sin(angle)) * (cell.current_radius + 40.0)
			var pulse = (sin(time * 5.0 + i) + 1.0) * 0.5
			var spike_color = Color. RED.lerp(Color(1, 0.2, 0.2), pulse)
			cell.draw_line(p1, p2, spike_color, 6.0)
	
	# ...  rest of draw code ... 
	
	# 2. Leader - Crown
	if cell.current_role == 1:  # LEADER
		for i in range(6):
			var angle = (PI * 2 / 6) * i
			var p = Vector2(cos(angle), sin(angle)) * (cell.current_radius * 1.3)
			cell.draw_circle(p, 4.0, Color(1.0, 1.5, 2.5, 0.6))
	
	# 3. Defense - Spiky armor
	if cell.current_role == 3:  # DEFENSE
		for i in range(8):
			var angle = (PI * 2 / 8) * i
			var p1 = Vector2(cos(angle), sin(angle)) * cell.current_radius
			var p2 = Vector2(cos(angle), sin(angle)) * (cell.current_radius + 25.0)
			cell.draw_line(p1, p2, Color(2.5, 1.0, 1.0), 4.0)
	
	# 4. Neural - Pulsing center
	if cell.current_role == 4:  # NEURAL
		var pulse = (sin(time * 10.0) + 1.0) * 0.5
		cell.draw_circle(Vector2.ZERO, cell.current_radius * 0.8, Color(2.0, 2.0, 1.0, pulse * 0.3))
	
	# 5. Survivor - Fast stripes (speed lines)
	if cell.current_role == 6:  # SURVIVOR
		cell.modulate = Color(0.5, 2.0, 0.5)
		for i in range(3):
			var offset = sin(time * 8.0 + i) * 15.0
			var p1 = Vector2(-cell.current_radius, offset)
			var p2 = Vector2(cell.current_radius, offset)
			cell.draw_line(p1, p2, Color(0.5, 2.0, 0.5, 0.4), 2.0)
	
	# 6. Storage - No special visuals (just big)
	if cell.current_role == 2:  # STORAGE
		pass
	
	# 7. Stinger - Tail
	if cell.current_role == 7:  # STINGER
		draw_stinger_tail(cell, time)
	
	# 8. Mega Colossus
	if cell.is_mega_fused and cell.mega_type == "Colossus":
		for i in range(12):
			var angle = (PI * 2 / 12) * i
			var p = Vector2(cos(angle), sin(angle)) * (cell.current_radius + 20.0)
			cell.draw_circle(p, 12.0, Color(0.3, 0.3, 0.3, 0.7))

func draw_stinger_tail(cell: Node2D, time:  float):
	var move_dir = cell.global_position.direction_to(cell.target_pos) if cell.global_position.distance_to(cell.target_pos) > 15.0 else Vector2.RIGHT
	var tail_dir = -move_dir
	
	var tail_points = []
	var t = time * 0.005
	
	for i in range(12):
		var progress = float(i) / 12.0
		var tail_length = cell.current_radius + (progress * 80.0)
		
		var angle = tail_dir.angle()
		angle += sin(t + i * 0.3) * 0.6 * (1.0 - progress)
		
		var wave_x = cos(angle) * tail_length
		var wave_y = sin(angle) * tail_length + sin(t * 2.0 + i) * (20.0 * (1.0 - progress))
		
		tail_points.append(Vector2(wave_x, wave_y))
	
	cell.draw_polyline(tail_points, Color(0.8, 0.2, 0.8), 4.0)
