extends RefCounted
class_name CellVisuals

# --- INITIAL NUCLEUS SHAPE ---
func update_nucleus_shape(cell: Node2D) -> void:
	if not cell.has_node("Nucleus"):
		return

	var nucleus: Polygon2D = cell.nucleus
	var points: PackedVector2Array = []

	var radius = cell.nucleus_size
	var count = 16

	for i in range(count):
		var angle = TAU * float(i) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	nucleus.polygon = points


# --- MEMBRANE UPDATE ---
func update_membrane(cell: Node2D, time: float, delta: float) -> void:
	if not cell.has_node("Polygon2D"):
		return

	var membrane: Polygon2D = cell.membrane
	var points: PackedVector2Array = []

	var dna_size: float = cell.genetics.dna["size"]
	var base_radius = lerp(
		cell.base_membrane_radius,
		cell.max_membrane_radius,
		cell.energy / 100.0
	) * dna_size

	for i in range(cell.vertex_count):
		var angle = TAU * float(i) / float(cell.vertex_count)

		var wobble = cell.noise.get_noise_2d(
			cos(angle) + time,
			sin(angle) + time
		) * cell.wobble_intensity * 10.0

		var r = base_radius + wobble
		points.append(Vector2(cos(angle), sin(angle)) * r)

	membrane.polygon = points


# --- NUCLEUS VISUAL ANIMATION ---
func update_nucleus_visuals(cell: Node2D, delta: float, time: float) -> void:
	var pulse = 1.0 + sin(time * 4.0) * 0.05
	cell.nucleus.scale = Vector2.ONE * pulse


# --- CUSTOM DRAW (OPTIONAL OVERLAYS) ---
func draw(cell: Node2D, time: float) -> void:
	# Example: signal pulse ring
	if cell.signal_pulse > 0.01:
		var alpha = clamp(cell.signal_pulse, 0.0, 1.0)
		cell.draw_circle(
			Vector2.ZERO,
			cell.current_radius * (1.2 + (1.0 - alpha)),
			Color(1, 1, 1, alpha * 0.2)
		)
