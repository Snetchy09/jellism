extends RefCounted
class_name CellVisuals

func update_nucleus_shape(cell: Node2D):
	var n_pts = []
	for i in range(12):
		var a = (PI * 2 / 12) * i
		n_pts.append(Vector2(cos(a), sin(a)) * 18.0)
	cell.nucleus.polygon = n_pts

func update_nucleus_visuals(cell: Node2D, delta: float, time: float):
	var energy_ratio = clamp(cell.energy / 100.0, 0.0, 1.0)
	var starving_color = Color(2, 0, 0)
	var healthy_color = Color(0, 2, 0)
	var base_color = starving_color.lerp(healthy_color, energy_ratio)
	
	if cell.energy >= cell.full_threshold:
		var pulse = (sin(time * 8.0) + 1.0) * 0.5
		var ready_color = Color(3.0, 3.0, 5.0)
		cell.nucleus.modulate = base_color.lerp(ready_color, pulse * 0.5)
	else:
		cell.nucleus.modulate = base_color

func draw(cell: Node2D, time: float = 0.0):
	if cell.is_being_eaten and is_instance_valid(cell.being_eaten_by):
		var eaten_pulse = sin(time * 15.0) * 0.5 + 0.5
		cell.draw_circle(Vector2.ZERO, cell.current_radius, Color(2.0, 0.0, 0.0, eaten_pulse * 0.5))
		
		var suction_count = int(cell.eaten_amount * 16.0)
		for i in range(suction_count):
			var angle = (PI * 2 / 16.0) * i
			var p1 = Vector2(cos(angle), sin(angle)) * cell.current_radius
			var p2 = Vector2(cos(angle), sin(angle)) * (cell.current_radius * 0.4)
			cell.draw_line(p1, p2, Color(3.0, 0.0, 0.0, 0.8), 4.0)
		return
	
	var spikiness = cell.genetics.dna["spikiness"]
	var hairiness = cell.genetics.dna["hairiness"]
	
	if spikiness > 0.3:
		var spike_count = int(12.0 + spikiness * 12.0)
		for i in range(spike_count):
			var angle = (PI * 2 / spike_count) * i
			var p1 = Vector2(cos(angle), sin(angle)) * cell.current_radius
			var spike_len = cell.current_radius * (0.3 + spikiness * 0.7)
			var p2 = Vector2(cos(angle), sin(angle)) * (cell.current_radius + spike_len)
			var pulse = (sin(time * 5.0 + i) + 1.0) * 0.5
			var spike_color = cell.modulate.lerp(Color.WHITE, pulse * 0.3)
			cell.draw_line(p1, p2, spike_color, 3.0 + spikiness * 3.0)
	
	if hairiness > 0.2:
		var hair_count = int(24.0 + hairiness * 40.0)
		for i in range(hair_count):
			var angle = (PI * 2 / hair_count) * i
			var base_pos = Vector2(cos(angle), sin(angle)) * cell.current_radius
			var hair_len = cell.current_radius * (0.2 + hairiness * 0.5)
			var wave = sin(time * 8.0 + i * 0.5) * hair_len * 0.3
			var hair_end = base_pos + Vector2(cos(angle), sin(angle)) * hair_len + Vector2(wave, 0)
			var hair_color = cell.modulate * 0.6
			cell.draw_line(base_pos, hair_end, hair_color, 1.0)

func update_membrane(cell: Node2D, time: float, delta: float) -> void:
	if not cell.has_node("Polygon2D"):
		return

	var membrane: Polygon2D = cell.membrane
	var points: PackedVector2Array = []

	var dna_size = cell.genetics.dna["size_modifier"]
	var base_radius = lerp(
		cell.base_membrane_radius,
		cell.max_membrane_radius,
		cell.energy / 100.0
	) * dna_size

	for i in range(cell.vertex_count):
		var angle = TAU * float(i) / float(cell.vertex_count)
		var wobble = cell.noise.get_noise_2d(cos(angle) + time, sin(angle) + time) * cell.wobble_intensity * 10.0
		var r = base_radius + wobble
		points.append(Vector2(cos(angle), sin(angle)) * r)

	membrane.polygon = points
