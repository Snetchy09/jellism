class_name CellPhysics

func apply_separation(cell: Node2D, delta: float):
	var others = cell.get_tree().get_nodes_in_group("cells")
	for other in others:
		if other == cell or other in cell.connected_cells:
			continue
		
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
			
			var force = other.global_position.direction_to(cell.global_position) * (min_dist - dist) * push_strength
			cell.external_force += force * delta

func apply_bond_physics(cell: Node2D, delta: float):
	for other in cell.connected_cells:
		var dist = cell.global_position.distance_to(other.global_position)
		var target_dist = (cell.current_radius + other.current_radius) * 0.8
		var force = cell.global_position.direction_to(other.global_position) * (dist - target_dist) * 8.0
		cell.external_force += force
		
		var pull_dist = cell.global_position.distance_to(other.global_position)
		if cell.organism_level == 1 and pull_dist > cell.current_radius * 3.0:
			if randf() < 0.01:
				cell.connected_cells.erase(other)
				other.connected_cells.erase(cell)

func update_membrane(cell: Node2D, time: float, delta: float):
	var local_poly = PackedVector2Array()
	var move_dir = cell.global_position.direction_to(cell.target_pos)
	
	var spikiness = cell.genetics.dna["spikiness"]
	var hairiness = cell.genetics.dna["hairiness"]
	var neck_length = cell.genetics.dna["neck_length"]
	var waviness = cell.genetics.dna["membrane_waviness"]
	
	for i in range(cell.vertex_count):
		var angle = (PI * 2 / cell.vertex_count) * i
		var dir_vec = Vector2(cos(angle), sin(angle))
		
		var wobble = cell.noise.get_noise_2d(i * 10.0, time * 2.0) * (cell.current_radius * 0.25) * waviness
		var v_target_radius = cell.current_radius + wobble
		
		if cell.global_position.distance_to(cell.target_pos) > 15.0 and not cell.is_splitting:
			v_target_radius += dir_vec.dot(move_dir) * (cell.current_radius * 0.5)
		
		if spikiness > 0.3 and i % int(1.0 + (1.0 - spikiness) * 4.0) == 0:
			v_target_radius += cell.current_radius * spikiness * 0.6
		
		if neck_length > 0.2:
			var move_alignment = dir_vec.dot(move_dir)
			if move_alignment > 0.5:
				v_target_radius += cell.current_radius * neck_length * move_alignment
		
		var v_target = cell.global_position + (dir_vec * v_target_radius)
		
		for other in cell.connected_cells:
			if not is_instance_valid(other):
				continue
			
			var to_other = (other.global_position - cell.global_position).normalized()
			var dist_to_other = cell.global_position.distance_to(other.global_position)
			var alignment = dir_vec.dot(to_other)
			
			if alignment > 0.05:
				var mid_point_dist = dist_to_other * 0.5
				var stretch_to_mid = mid_point_dist / alignment
				var max_stretch = cell.current_radius * 1.8
				stretch_to_mid = min(stretch_to_mid, max_stretch)
				
				var blend = pow(alignment, 1.2)
				v_target = v_target.lerp(cell.global_position + (dir_vec * stretch_to_mid), blend)
		
		if cell.is_splitting:
			var squeeze = abs(sin(angle))
			v_target = cell.global_position + (v_target - cell.global_position) * (1.0 - (squeeze * cell.pinch_amount * 1.2))
		
		var force = (v_target - cell.global_vertices[i]) * cell.stiffness
		
		if v_target.distance_to(cell.global_position) > cell.current_radius * 1.1:
			force *= 2.0
		
		cell.velocities[i] += force * delta
		cell.velocities[i] -= cell.velocities[i] * cell.damping * delta
		cell.global_vertices[i] += cell.velocities[i] * delta
		
		local_poly.append(cell.to_local(cell.global_vertices[i]))
	
	cell.membrane.polygon = local_poly

func _apply_role_deformation(cell: Node2D, i: int, time: float, radius: float) -> float:
	if cell.current_role == 0:
		return radius
	elif cell.current_role == 3:
		if i % 2 == 0:
			return radius + 15.0
		return radius
	elif cell.current_role == 2:
		return radius * 1.4
	elif cell.current_role == 4:
		return radius + sin(time * 15.0) * 5.0
	else:
		return radius
