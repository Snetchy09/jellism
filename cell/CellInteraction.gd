class_name CellInteraction

var eating_target: Node2D = null
var eating_progress: float = 0.0

func handle_area_entered(cell: Node2D, area: Area2D):
	if cell. is_splitting:
		return
	
	# 1. FOOD
	if area.is_in_group("food"):
		print("DEBUG: Eating food!")
		area.queue_free()
		cell.energy = clamp(cell.energy + 25.0, 0, 150)
		if cell.energy >= 110.0:
			cell.reproduction.start_division(cell)
		return
	
	# 2. CELL INTERACTION - Find the OTHER cell
	# The area that collided with us - get ITS parent cell
	var other_cell = null
	if area.get_parent().is_in_group("cells"):
		other_cell = area.get_parent()
	elif area.get_parent().get_parent() and area.get_parent().get_parent().is_in_group("cells"):
		other_cell = area.get_parent().get_parent()
	
	if not other_cell or other_cell == cell:
		return
	
	print("DEBUG:  CELL COLLISION!  Me:  ", cell.name, " (role ", cell.current_role, ") Other: ", other_cell.name, " (role ", other_cell.current_role, ")")
	
	# CARNIVORE EATING
	if cell.current_role == 5:  # CARNIVORE
		print("🔴 CARNIVORE ATTACKING!")
		if not eating_target or not is_instance_valid(eating_target):
			eating_target = other_cell
			eating_progress = 0.0
			print("🔴 STARTED EATING PREY")
		return
	
	# FLEE FROM CARNIVORE
	if other_cell.current_role == 5 and other_cell. organism_level >= 1:
		print("DEBUG: ", cell.name, " FLEEING FROM CARNIVORE")
		cell.external_force += (cell.global_position - other_cell.global_position).normalized() * 1000
		return
	
	# RARE MERGING
	if cell.connected_cells.size() < cell.max_connections and other_cell.connected_cells. size() < cell.max_connections:
		if other_cell not in cell.connected_cells:
			var fusion_chance = 0.02 if cell.organism_level == 1 else 0.005
			if randf() < fusion_chance:
				cell.connected_cells.append(other_cell)
				other_cell.connected_cells.append(cell)
				print("Organism Fusion!")

func update_eating(cell: Node2D, delta: float):
	# If no target or target is dead, stop eating
	if not eating_target or not is_instance_valid(eating_target):
		eating_target = null
		eating_progress = 0.0
		return
	
	# Check if still in range
	var dist = cell.global_position.distance_to(eating_target.global_position)
	var max_eating_range = (cell.current_radius + eating_target.current_radius) * 3.0
	
	if dist > max_eating_range: 
		eating_target = null
		eating_progress = 0.0
		return
	
	# Circle around the target
	var target_dir = (eating_target.global_position - cell.global_position).normalized()
	var circle_dir = target_dir.rotated(PI / 2.0)
	var circle_velocity = circle_dir * 150.0
	cell.global_position += circle_velocity * delta
	
	# Increment eating progress
	eating_progress += delta / cell.digestion_time
	
	# Scale damage by organism level
	var damage_per_second = 20.0
	if cell.organism_level == 1:
		damage_per_second = 20.0
	elif cell.organism_level == 2:
		damage_per_second = 35.0
	else:
		damage_per_second = 50.0
	
	# Deal damage
	eating_target.energy -= damage_per_second * delta
	eating_target. is_being_eaten = true
	eating_target.being_eaten_by = cell
	eating_target.eaten_amount = eating_progress
	
	# Pull prey toward carnivore
	eating_target.external_force += (eating_target.global_position - cell. global_position).normalized() * 500.0
	
	print("🔴 EATING PROGRESS: ", eating_progress * 100, "% | Prey HP: ", eating_target.energy)
	
	# When finished eating
	if eating_target.energy <= 0 or eating_progress >= 1.0:
		finish_eating(cell, eating_target)
		eating_target = null
		eating_progress = 0.0

func finish_eating(cell: Node2D, prey: Node2D):
	var energy_gained = 60.0
	if prey.organism_level >= 2:
		energy_gained = 90.0
	if prey.organism_level >= 3:
		energy_gained = 120.0
	
	cell. energy = clamp(cell.energy + energy_gained, 0, 150)
	prey.queue_free()
	
	print("🔴 MEAL COMPLETE!  Gained: ", energy_gained, " energy")
	
	if cell.energy >= 120.0:
		cell.reproduction.start_division(cell)

func handle_sense_entered(cell: Node2D, area: Area2D):
	var node = area if area.is_in_group("food") else area.get_parent()
	if node.is_in_group("food"):
		cell.food_in_range. append(node)

func handle_sense_exited(cell: Node2D, area:  Area2D):
	var node = area if area.is_in_group("food") else area.get_parent()
	if node in cell.food_in_range:
		cell.food_in_range.erase(node)

func attack_cell(cell: Node2D, target: Node2D):
	var damage = 15.0
	
	# Scale damage by organism level
	if cell.organism_level == 1:
		damage = 20.0  # Increased from 3% (was 0.3 * 15)
	elif cell.organism_level == 2:
		damage = 35.0  # Increased from 70%
	elif cell.organism_level >= 3:
		damage = 50.0  # Increased from 150%
	
	# HERBIVORE DEFENSES reduce damage
	if target.current_role == 3:  # DEFENSE role
		damage *= 0.15  # Take only 15% damage
		cell.external_force += (cell.global_position - target.global_position).normalized() * 500
	elif target.current_role == 6:  # SURVIVOR role
		damage *= 0.5  # Take 50% damage
		target.external_force += (target.global_position - cell.global_position).normalized() * 800
	
	# Apply damage
	target.energy -= damage
	cell.energy = clamp(cell.energy + (damage * 0.5), 0, 150)
	
	# PUSH THEM APART - This prevents sticking
	var push_force = 600.0
	target.external_force += (target. global_position - cell.global_position).normalized() * push_force
	cell.external_force += (cell.global_position - target.global_position).normalized() * (push_force * 0.5)
	
	print("🔴 CARNIVORE ATTACK!  Damage:  ", damage, " Target HP: ", target.energy)
