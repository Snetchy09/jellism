class_name CellEvolution

enum Role { UNIFORM, LEADER, STORAGE, DEFENSE, NEURAL, CARNIVORE, SURVIVOR, STINGER }

var connection_maturity: Dictionary = {}

func check_evolution(cell: Node2D):
	if cell.connected_cells.size() == 0:
		cell.maturity = 0
		cell.organism_level = 1
		
		# PRESERVE CARNIVORE ROLE - don't reset it! 
		if cell.current_role != 5:  # Only reset if NOT carnivore
			cell.current_role = Role.UNIFORM
		
		connection_maturity. clear()
		return
	
	# Calculate stability
	var total_stability = 0.0
	var stable_connections = 0
	
	for other in cell.connected_cells:
		var dist = cell.global_position.  distance_to(other.global_position)
		var target = (cell.current_radius + other.current_radius) * 0.8
		var stability = clamp(1.0 - (abs(dist - target) / 100.0), 0.0, 1.0)
		
		total_stability += stability
		
		if other not in connection_maturity:
			connection_maturity[other] = 0.0
		
		if stability > 0.7:
			connection_maturity[other] += 0.5
			if stability > 0.9:
				stable_connections += 1
		else:
			connection_maturity[other] -= 1.0
			
			if connection_maturity[other] <= 0.0:
				cell.connected_cells.erase(other)
				other.connected_cells.erase(cell)
				connection_maturity.erase(other)
				print("Connection failed!")
				return
	
	var avg_stability = total_stability / cell.connected_cells.size()
	
	if stable_connections >= cell.connected_cells.size() * 0.7:
		cell.maturity += 1.0
	else:
		cell.maturity -= 0.5
	
	# Level up
	if cell.maturity > 300:
		cell.organism_level = 3
	elif cell.maturity > 120:
		cell.organism_level = 2
	else:
		cell.organism_level = 1
	
	# Assign roles - BUT SKIP IF ALREADY CARNIVORE
	if cell.current_role != 5:  # Only assign if not carnivore
		if cell.organism_level == 2:
			assign_mid_roles(cell)
		elif cell.organism_level == 3:
			assign_high_roles(cell)
	
	# Mega fusion
	if cell.maturity > 500 and not cell.is_mega_fused:
		if randf() < 0.01:
			trigger_mega_fusion(cell)

func assign_mid_roles(cell: Node2D):
	var leader = cell
	for c in cell.connected_cells:
		if c. energy > leader.energy:
			leader = c
	
	if leader == cell:
		cell.current_role = Role. LEADER
		cell.modulate = Color(1.0, 1.3, 2.0)
	else:
		cell.current_role = Role.STORAGE
		cell.modulate = Color(1.8, 1.5, 1.0)

func assign_high_roles(cell: Node2D):
	var role_idx = hash(cell) % 6  # Now 6 roles instead of 5
	
	if role_idx == 0:
		cell.current_role = Role.LEADER
		cell.modulate = Color(1.0, 1.5, 2.5)
	elif role_idx == 1:
		cell.current_role = Role.DEFENSE
		cell.modulate = Color(2.5, 1.0, 1.0)
	elif role_idx == 2:
		cell.current_role = Role.NEURAL
		cell.modulate = Color(2.0, 2.0, 1.0)
	elif role_idx == 3:
		cell.current_role = Role.STINGER
		cell.modulate = Color(0.8, 0.2, 0.8)
	elif role_idx == 4:
		cell.current_role = Role.SURVIVOR  # NEW:  Fast escape artist
		cell.modulate = Color(0.5, 2.0, 0.5)
	else: 
		cell.current_role = Role.STORAGE
		cell.modulate = Color(1.5, 1.0, 2.0)

func trigger_mega_fusion(cell: Node2D):
	cell.is_mega_fused = true
	var types = ["Colossus", "Stinger"]
	cell.mega_type = types. pick_random()
	
	if cell.mega_type == "Colossus":
		cell. current_radius *= 2.5
		cell.modulate = Color(0.4, 0.4, 0.4)
	elif cell.mega_type == "Stinger":
		cell.modulate = Color(0.8, 0.2, 0.8)
