extends Node2D
class_name WasteCloud

static var _instance: WasteCloud = null

var waste_map: Dictionary = {}
var waste_cell_size: float = 50.0
var waste_decay_rate: float = 0.5

# ✅ SAFE static accessor
static func get_instance() -> WasteCloud:
	if _instance == null:
		_instance = WasteCloud.new()
	return _instance

# ✅ Scene-tree access happens HERE (non-static)
func _ready() -> void:
	if _instance == null:
		_instance = self
		add_to_group("waste_cloud")
	elif _instance != self:
		queue_free()
		return

	if get_parent() == null:
		get_tree().root.add_child(self)


func add_waste(world_pos: Vector2, amount: float):
	var grid_pos = (world_pos / waste_cell_size).round() * waste_cell_size
	if grid_pos not in waste_map:
		waste_map[grid_pos] = 0.0
	waste_map[grid_pos] += amount

func get_waste_at(world_pos: Vector2) -> float:
	var grid_pos = (world_pos / waste_cell_size).round() * waste_cell_size
	return waste_map.get(grid_pos, 0.0)

func get_waste_color(amount: float) -> Color:
	var normalized = clamp(amount / 100.0, 0.0, 1.0)
	var brown = Color(0.4, 0.3, 0.2)
	var gray = Color(0.5, 0.5, 0.5)
	var color = brown.lerp(gray, normalized)
	color.a = normalized * 0.6
	return color

func _process(delta):
	for grid_pos in waste_map.keys():
		waste_map[grid_pos] -= waste_decay_rate * delta
		if waste_map[grid_pos] <= 0.0:
			waste_map.erase(grid_pos)
