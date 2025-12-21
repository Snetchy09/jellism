class_name CellPhysics

func apply_separation(cell: Node2D, delta:  float):
	var others = cell.get_tree().get_nodes_in_group("cells")
	for other in others:
		if other == cell or other in cell.connected_cells:
			continue
		
		# Don't push apart if being eaten
		if other.is_being_eaten:
			continue
		if cell.is_being_eaten:
			continue
		
		var dist = cell.global_position.distance_to(other.global_position)
		var min_dist = (cell.current_radius + other.current_radius) * 0.9
		
		if dist < min_dist and dist > 0.1:
			var push_strength = 150.0
			if cell.current_role == 5:
				push_strength = 250.0
			
			var force = other. global_position.direction_to(cell.global_position) * (min_dist - dist) * push_strength
			cell.external_force += force * delta

func apply_bond_physics(cell: Node2D, delta: float):
	for other in cell.connected_cells:
		var dist = cell.global_position. distance_to(other.global_position)
		var target_dist = (cell.current_radius + other.current_radius) * 0.8
		var force = cell.global_position.direction_to(other.global_position) * (dist - target_dist) * 8.0
		cell.external_force += force
		
		# Snap if stretched too far
		var pull_dist = cell.global_position.distance_to(other.global_position)
		if cell.organism_level == 1 and pull_dist > cell.current_radius * 3.0:
			if randf() < 0.01:
				cell.connected_cells.erase(other)
				other.connected_cells. erase(cell)
				print("Connection Snapped!")

func update_membrane(cell: Node2D, time: float, delta: float):
	var local_poly = PackedVector2Array()
	var move_dir = cell.global_position.direction_to(cell.target_pos)
	
	for i in range(cell.vertex_count):
		var angle = (PI * 2 / cell.vertex_count) * i
		var dir_vec = Vector2(cos(angle), sin(angle))
		
		# 1. BASE ORGANIC SHAPE
		var wobble = cell.noise. get_noise_2d(i * 10.0, time * 2.0) * (cell.current_radius * 0.25)
		var v_target_radius = cell.current_radius + wobble
		
		# 2. MOVEMENT DEFORMATION
		if cell.global_position.distance_to(cell.target_pos) > 15.0 and not cell.is_splitting:
			v_target_radius += dir_vec.dot(move_dir) * (cell.current_radius * 0.5)
		
		# 3. ROLE VISUALS - Get modified radius
		v_target_radius = _apply_role_deformation(cell, i, time, v_target_radius)
		var v_target = cell.global_position + (dir_vec * v_target_radius)
		
		# 4. FAT FUSION LOGIC
		for other in cell.connected_cells:
			if not is_instance_valid(other):
				continue
			
			var to_other = (other.global_position - cell.global_position).normalized()
			var dist_to_other = cell.global_position.distance_to(other. global_position)
			var alignment = dir_vec.dot(to_other)
			
			if alignment > 0.05:
				var mid_point_dist = dist_to_other * 0.5
				var stretch_to_mid = mid_point_dist / alignment
				var max_stretch = cell.current_radius * 1.8
				stretch_to_mid = min(stretch_to_mid, max_stretch)
				
				var blend = pow(alignment, 1.2)
				v_target = v_target.lerp(cell.global_position + (dir_vec * stretch_to_mid), blend)
		
		# 5. PINCH (splitting)
		if cell.is_splitting:
			var squeeze = abs(sin(angle))
			v_target = cell.global_position + (v_target - cell.global_position) * (1.0 - (squeeze * cell.pinch_amount * 1.2))
		
		# 6. SOFT JELLY PHYSICS
		var force = (v_target - cell.global_vertices[i]) * cell.stiffness
		
		if v_target.distance_to(cell.global_position) > cell.current_radius * 1.1:
			force *= 2.0
		
		cell.velocities[i] += force * delta
		cell.velocities[i] -= cell.velocities[i] * cell.damping * delta
		cell.global_vertices[i] += cell.velocities[i] * delta
		
		local_poly.append(cell.to_local(cell.global_vertices[i]))
	
	cell.membrane. polygon = local_poly

func _apply_role_deformation(cell: Node2D, i: int, time: float, radius: float) -> float:
	if cell.current_role == 0:  # UNIFORM
		return radius
	elif cell.current_role == 3:  # DEFENSE
		if i % 2 == 0:
			return radius + 15.0
		return radius
	elif cell.current_role == 2:  # STORAGE
		return radius * 1.4
	elif cell.current_role == 4:  # NEURAL
		return radius + sin(time * 15.0) * 5.0
	else: 
		return radius
