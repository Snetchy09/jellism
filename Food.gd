extends Area2D

const FOOD_SCENE: PackedScene = preload("res://Food.tscn")

var velocity: Vector2 = Vector2.ZERO
var noise_offset: float = randf() * 100.0

@onready var poly: Polygon2D = $Polygon2D

# Life-like properties
@export var energy: float = 8.0
@export var energy_decay: float = 0.15
@export var max_age: float = 80.0
@export var division_energy: float = 14.0
@export var division_chance: float = 0.25

var age: float = 0.0

func _ready():
	# Random initial drift
	velocity = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	add_to_group("food")

func _process(delta):
	age += delta
	energy -= energy_decay * delta
	
	# Move
	position += velocity * delta
	
	# Brownian motion (random wobbling)
	var time = Time.get_ticks_msec() * 0.001
	velocity.x += sin(time + noise_offset) * 2.0
	velocity.y += cos(time + noise_offset) * 2.0
	velocity = velocity.limit_length(30.0)
	
	# Bounce off screen edges
	var screen_size = get_viewport_rect().size
	if position.x < 0 or position.x > screen_size.x:
		velocity.x *= -1
	if position.y < 0 or position.y > screen_size.y:
		velocity.y *= -1
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# Visual "micro-organism" pulsing
	var pulse: float = sin(time * 3.0 + noise_offset) * 0.1 + 1.0
	scale = Vector2.ONE * pulse
	
	# Color based on energy (brighter when "rich")
	if poly:
		var energy_ratio: float = clamp(energy / division_energy, 0.0, 1.0)
		var base_color := Color(0.3, 0.9, 0.4)
		var rich_color := Color(0.9, 1.2, 0.6)
		poly.modulate = base_color.lerp(rich_color, energy_ratio * pulse)
	
	# Life cycle: die when out of energy or too old
	if energy <= 0.0 or age >= max_age:
		queue_free()
		return
	
	# Occasional simple division
	if energy >= division_energy and randf() < division_chance * delta:
		_divide()

func _divide():
	energy *= 0.5
	if FOOD_SCENE:
		var child: Area2D = FOOD_SCENE.instantiate()
		child.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(child)
