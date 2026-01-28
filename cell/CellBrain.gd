class_name CellBrain

func decide_behavior(cell: Node2D, delta: float, time: float) -> void:
	cell.food_in_range = cell.food_in_range.filter(func(a): return is_instance_valid(a))
	
	# ✅ Use the correct DNA key
	var speed_mod: float = cell.genetics.dna["speed_modifier"]
	var speed = 120.0 * speed_mod / (1.0 + cell.connected_cells.size() * 0.5)
	
	# ✅ Other DNA values
	var filter_feeding: float = cell.genetics.dna["filter_feeding"]
	var neck_length: float = cell.genetics.dna["neck_length"]
	var aggression: float = cell.genetics.dna["aggression"]
	
	if aggression > 0.6:
		speed *= 1.5
		var nearest_cell: Node2D = null
		var nearest_dist := INF
		
		for other in cell.get_tree().get_nodes_in_group("cells"):
			if other == cell:
				continue
			if other.genetics.dna["aggression"] > 0.6:
				continue
			
			var dist = cell.global_position.distance_to(other.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_cell = other
		
		if nearest_cell and nearest_dist < 600.0:
			cell.target_pos = nearest_cell.global_position
			cell.global_position += cell.global_position.direction_to(cell.target_pos) * speed * delta
			return
	
	# --- feeding behavior ---
	if filter_feeding > 0.5:
		if cell.food_in_range.size() > 0:
			cell.target_pos = cell.food_in_range[0].global_position
			cell.global_position += cell.global_position.direction_to(cell.target_pos) * speed * delta
			return
	
	# --- follow shared signal ---
	if cell.food_in_range.size() > 0:
		cell.target_pos = cell.food_in_range[0].global_position
		cell.global_position += cell.global_position.direction_to(cell.target_pos) * speed * delta
	elif cell.shared_target != Vector2.ZERO and cell.global_position.distance_to(cell.shared_target) > 50.0:
		cell.global_position += cell.global_position.direction_to(cell.shared_target) * speed * delta
	else:
		# idle drift
		var drift = Vector2(
			cell.noise.get_noise_2d(time * 5.0, 0.0),
			cell.noise.get_noise_2d(0.0, time * 5.0)
		).normalized()
		cell.global_position += drift * 30.0 * delta
