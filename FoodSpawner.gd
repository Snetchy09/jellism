extends Node2D

@export var food_scene: PackedScene = preload("res://Food.tscn")
@export var spawn_interval: float = 0.5
@export var max_food: int = 25
@export var world_half_extents: Vector2 = Vector2(2000, 2000)
@export var bacteria_spawn_chance: float = 0.02

var rng := RandomNumberGenerator.new()
var bacteria_scene: PackedScene

func _ready():
	rng.randomize()
	bacteria_scene = preload("res://Bacteria.tscn")
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_spawn_timer)
	timer.start()

func _on_spawn_timer():
	var cell_count = get_tree().get_nodes_in_group("cells").size()
	var waste_cloud = WasteCloud.get_instance()
	
	var current_food = get_tree().get_nodes_in_group("food").size()
	var food_spawn_modifier = 1.0 - (cell_count / 200.0)
	food_spawn_modifier = clamp(food_spawn_modifier, 0.2, 1.0)
	var adjusted_max = int(max_food * food_spawn_modifier)
	
	if current_food < adjusted_max:
		var food = food_scene.instantiate()
		
		var spawn_pos = Vector2.ZERO
		var attempts = 0
		var max_attempts = 5
		
		while attempts < max_attempts:
			spawn_pos = Vector2(
				rng.randf_range(-world_half_extents.x, world_half_extents.x),
				rng.randf_range(-world_half_extents.y, world_half_extents.y)
			)
			
			var waste = waste_cloud.get_waste_at(spawn_pos)
			
			if waste < 10.0:
				break
			elif waste < 30.0 and randf() < 0.5:
				break
			
			attempts += 1
		
		get_parent().add_child(food)
		food.global_position = spawn_pos
	
	if randf() < bacteria_spawn_chance and waste_cloud.waste_map.size() > 0:
		var random_waste_pos = waste_cloud.waste_map.keys().pick_random()
		var bacteria = bacteria_scene.instantiate()
		get_parent().add_child(bacteria)
		bacteria.global_position = random_waste_pos
