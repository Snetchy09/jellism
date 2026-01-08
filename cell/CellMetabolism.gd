class_name CellMetabolism

func update(cell: Node2D, delta: float) -> void:
	var metabolism_mod: float = cell.genetics.dna["metabolism"]
	var energy_eff: float = cell.genetics.dna["metabolism"]

	var decay = cell.energy_decay_rate * metabolism_mod / energy_eff
	cell.energy -= decay * delta

	cell.current_radius = lerp(
		40.0,
		80.0,
		cell.energy / 100.0
	) * cell.genetics.dna["size"]

	if cell.energy <= 0.0:
		cell.queue_free()


func share_resources_and_signals(cell: Node2D, delta: float):
	cell.connected_cells = cell.connected_cells.filter(func(c): return is_instance_valid(c))
	
	for other in cell.connected_cells:
		var diff = cell.energy - other.energy
		if diff > 10.0:
			var transfer = diff * delta * 0.5
			cell.energy -= transfer
			other.energy += transfer
		
		if other.food_in_range.size() > 0:
			cell.shared_target = other.target_pos
			if cell.signal_pulse < 0.1:
				cell.signal_pulse = 1.0
