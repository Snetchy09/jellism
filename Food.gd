extends Area2D

var velocity := Vector2.ZERO
var noise_offset := randf() * 100.0

func _ready():
	# Random initial drift
	velocity = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	add_to_group("food")

func _process(delta):
	# Move
	position += velocity * delta
	
	# Brownian motion (random wobbling)
	var time = Time.get_ticks_msec() * 0.001
	velocity.x += sin(time + noise_offset) * 2.0
	velocity.y += cos(time + noise_offset) * 2.0
	velocity = velocity.limit_length(30.0)
	
	# Bounce off screen edges
	var screen_size = get_viewport_rect().size
	if position.x < 0 or position.x > screen_size.x: velocity.x *= -1
	if position.y < 0 or position.y > screen_size.y: velocity.y *= -1
	position = position.clamp(Vector2.ZERO, screen_size)
