extends Node2D

@export var food_scene: PackedScene = preload("res://Food.tscn") # Check your path!
@export var spawn_interval: float = 0.5
@export var max_food: int = 25

func _ready():
	# Start spawning
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_spawn_timer)
	timer.start()

func _on_spawn_timer():
	var current_food = get_tree().get_nodes_in_group("food").size()
	
	if current_food < max_food:
		var food = food_scene.instantiate()
		var screen_size = get_viewport_rect().size
		
		# Spawn at a random position
		food.position = Vector2(
			randf_range(-50, screen_size.x - 5),
			randf_range(-50, screen_size.y - 5)
		)
		
		get_parent().add_child(food)
