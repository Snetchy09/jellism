class_name Genetics

var dna: Dictionary = {}

func _init():
	dna = {
		"size_modifier": randf_range(0.8, 1.2),
		"speed_modifier": randf_range(0.8, 1.2),
		"metabolism_rate": randf_range(0.8, 1.2),
		"energy_efficiency": randf_range(0.8, 1.2),
		"aggression": randf_range(0.0, 1.0),
		
		"spikiness": randf_range(0.0, 1.0),
		"hairiness": randf_range(0.0, 1.0),
		"neck_length": randf_range(0.0, 1.0),
		"membrane_waviness": randf_range(0.5, 2.0),
		"filter_feeding": randf_range(0.0, 1.0),
		
		"color_r": randf_range(0.2, 1.0),
		"color_g": randf_range(0.2, 1.0),
		"color_b": randf_range(0.2, 1.0)
	}

func mutate():
	for key in dna.keys():
		if randf() < 0.1:
			if key.begins_with("color"):
				dna[key] += randf_range(-0.15, 0.15)
				dna[key] = clamp(dna[key], 0.2, 1.0)
			elif key in ["membrane_waviness"]:
				dna[key] += randf_range(-0.2, 0.2)
				dna[key] = clamp(dna[key], 0.5, 2.0)
			else:
				dna[key] += randf_range(-0.15, 0.15)
				dna[key] = clamp(dna[key], 0.0, 1.0)

func get_color() -> Color:
	return Color(dna["color_r"], dna["color_g"], dna["color_b"])

func copy() -> Genetics:
	var new_genetics = Genetics.new()
	new_genetics.dna = dna.duplicate()
	new_genetics.mutate()
	return new_genetics
