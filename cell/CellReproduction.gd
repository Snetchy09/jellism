class_name CellReproduction

var last_division_time: float = 0.0
var division_cooldown: float = 3.0
var age: float = 0.0
var maturation_age: float = 5.0

func update_age(delta: float):
	age += delta

func start_division(cell: Node2D) -> bool:
	if cell. is_splitting:
		return false
	
	var current_time = Time.get_ticks_msec() * 0.001
	if current_time - last_division_time < division_cooldown: 
		return false
	
	cell.is_splitting = true
	cell.pinch_amount = 0.0
	last_division_time = current_time
	return true

func complete_division(cell: Node2D):
	cell.is_splitting = false
	cell.pinch_amount = 0.0
	cell.energy = 45.0
	
	var split_dir = Vector2.LEFT.  rotated(randf() * PI * 2)
	var cell_scene = load("res://Cell.tscn")
	
	if cell_scene:
		var sister = cell_scene.instantiate()
		sister.global_position = cell.global_position
		cell.get_parent().add_child(sister)
		sister.energy = 45.0
		
		var should_stay_connected = false
		
		# CARNIVORES DON'T FORM BONDS
		if cell.current_role == 5:  # CARNIVORE
			should_stay_connected = false
		elif cell.organism_level == 1:  
			should_stay_connected = randf() < 0.15
		else:
			should_stay_connected = randf() < 0.5
		
		if should_stay_connected:
			cell.connected_cells.append(sister)
			sister.connected_cells.append(cell)
			
			if cell.organism_level >= 3:
				for friend in cell.connected_cells:
					if friend != sister and friend.connected_cells.size() < cell.max_connections:
						friend.connected_cells.append(sister)
						sister.connected_cells.append(friend)
			
			cell.external_force = split_dir * 120.0
			sister.external_force = -split_dir * 120.0
		else:
			cell.external_force = split_dir * 400.0
			sister.external_force = -split_dir * 400.0
		
		# Inherit traits
		sister.organism_level = cell.organism_level
		sister.maturity = cell.maturity
		
		# PROPERLY INHERIT CARNIVORE ROLE
		if cell.current_role == 5:  # If parent is carnivore
			sister. current_role = 5  # Sister is ALSO carnivore
			sister.modulate = Color(2.5, 0.1, 0.1)
			print("🔴 CARNIVORE OFFSPRING SPAWNED!")
		# Random chance for normal cells to mutate into carnivore (rare)
		elif cell.organism_level == 1 and randf() < 0.05:
			sister.current_role = 5
			sister.modulate = Color(2.5, 0.1, 0.1)
			print("🔴 WILD CARNIVORE MUTATION!")
		
		if cell.is_mega_fused: 
			sister.is_mega_fused = true
			sister. mega_type = cell.mega_type
