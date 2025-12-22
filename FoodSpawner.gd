extends Node2D

@export var food_scene: PackedScene = preload("res://Food.tscn") # Check your path!
@export var spawn_interval: float = 0.5
@export var max_food: int = 25
# Half-size of the world in each direction (you can tweak this in the editor)
@export var world_half_extents: Vector2 = Vector2(2000, 2000)

var rng := RandomNumberGenerator.new()

func _ready():
	# Start spawning
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
		
		# Spawn anywhere in the world rectangle centered at (0, 0)
		var spawn_pos := Vector2(
			rng.randf_range(-world_half_extents.x, world_half_extents.x),
			rng.randf_range(-world_half_extents.y, world_half_extents.y)
		)
		
		# Add to the world first, then set global position so it truly respects world coords
		get_parent().add_child(food)
		food.global_position = spawn_pos
