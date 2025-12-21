class_name CellBrain

func decide_behavior(cell: Node2D, delta: float, time: float):
	cell.food_in_range = cell.food_in_range.filter(func(a): return is_instance_valid(a))
	
	var speed = 120.0 / (1.0 + cell.connected_cells.size() * 0.5)
	
	# CARNIVORE HUNTING
	if cell.current_role == 5:  # CARNIVORE
		speed *= 2.5
		var nearest_cell = null
		var nearest_dist = 9999.0
		
		var others = cell.get_tree().get_nodes_in_group("cells")
		for other in others:
			if other == cell or other. current_role == 5:
				continue
			var dist = cell.global_position. distance_to(other.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_cell = other
		
		if nearest_cell and nearest_dist < 600.0:
			cell.target_pos = nearest_cell.global_position
			cell.global_position += cell.global_position.direction_to(cell.target_pos) * speed * delta
			return
		else:
			# Hunt randomly if no prey nearby
			var drift = Vector2(cell.noise.get_noise_2d(time * 5, 0), cell.noise.get_noise_2d(0, time * 5)).normalized()
			cell.global_position += drift * speed * delta
			return
	
	# SURVIVOR - Fast flee from danger
	if cell.current_role == 6:  # SURVIVOR
		speed *= 3.5
		
		var nearest_threat = null
		var nearest_threat_dist = 9999.0
		
		var others = cell.get_tree().get_nodes_in_group("cells")
		for other in others:
			if other == cell or other.current_role != 5:
				continue
			var dist = cell.global_position.distance_to(other.global_position)
			if dist < 400.0 and dist < nearest_threat_dist:
				nearest_threat_dist = dist
				nearest_threat = other
		
		if nearest_threat: 
			var flee_dir = (cell.global_position - nearest_threat.global_position).normalized()
			cell.target_pos = cell.global_position + flee_dir * 300.0
			cell.global_position += flee_dir * speed * delta
			return
	
	# REGULAR BEHAVIOR - Herbivores
	if cell.food_in_range.size() > 0:
		cell.target_pos = cell.food_in_range[0].global_position
		cell.global_position += cell.global_position. direction_to(cell.target_pos) * speed * delta
	elif cell.shared_target != Vector2.ZERO and cell.global_position. distance_to(cell.shared_target) > 50: 
		cell.global_position += cell.global_position.direction_to(cell.shared_target) * speed * delta
	else:
		var drift = Vector2(cell.noise.get_noise_2d(time * 5, 0), cell.noise.get_noise_2d(0, time * 5)).normalized()
		cell.global_position += drift * 30.0 * delta
