extends Node2D

@export var food_scene: PackedScene = preload("res://Food.tscn")
@export var spawn_interval: float = 0.5
@export var max_food: int = 25
@export var world_half_extents: Vector2 = Vector2(2000, 2000)

var rng := RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_spawn_timer)
	timer.start()

func _on_spawn_timer():
	var current_food = get_tree().get_nodes_in_group("food").size()
	
	if current_food < max_food:
		var food = food_scene.instantiate()
		
		var spawn_pos = Vector2.ZERO
		var attempts = 0
		var max_attempts = 5
		
		while attempts < max_attempts:
			spawn_pos = Vector2(
				rng.randf_range(-world_half_extents.x, world_half_extents.x),
				rng.randf_range(-world_half_extents.y, world_half_extents.y)
			)
			
			var waste = WasteCloud.get_instance().get_waste_at(spawn_pos)
			
			if waste < 10.0:
				break
			elif waste < 30.0 and randf() < 0.5:
				break
			
			attempts += 1
		
		get_parent().add_child(food)
		food.global_position = spawn_pos
