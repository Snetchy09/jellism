extends Area2D
class_name Bacteria

var age: float = 0.0
var max_age: float = 30.0
var velocity: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("bacteria")
	velocity = Vector2(randf_range(-30, 30), randf_range(-30, 30))

func _process(delta):
	age += delta
	
	position += velocity * delta
	velocity = velocity.lerp(Vector2.ZERO, delta * 0.5)
	
	var waste = WasteCloud.get_instance().get_waste_at(global_position)
	if waste > 5.0:
		position += Vector2(cos(age), sin(age * 0.7)).normalized() * 50.0 * delta
	
	if age >= max_age or position.distance_to(Vector2.ZERO) > 3000:
		queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("food"):
		area.queue_free()
		age = max_age - 2.0
