extends Node2D

var metabolism: CellMetabolism
var physics: CellPhysics
var brain: CellBrain
var evolution: CellEvolution
var reproduction: CellReproduction
var visuals: CellVisuals
var interaction: CellInteraction
var genetics: Genetics

@export_group("Metabolism")
@export var energy: float = 80.0
@export var energy_decay_rate: float = 1.5
@export var hunger_threshold: float = 60.0
@export var full_threshold: float = 95.0

@export_group("Growth")
@export var nucleus_size: float = 18.0
@export var max_nucleus_size: float = 40.0
@export var base_membrane_radius: float = 50.0
@export var max_membrane_radius: float = 85.0

@export_group("Physics")
@export var vertex_count: int = 32
@export var stiffness: float = 160.0
@export var damping: float = 14.0
@export var wobble_intensity: float = 0.25
@export var movement_deformation: float = 0.5
@export var fusion_blend_smoothness: float = 1.2
@export var fusion_max_stretch: float = 1.8

@export_group("Neural/Connections")
@export var max_connections: int = 2

var connected_cells: Array = []
var current_role: int = 0
var is_dragging: bool = false
var is_splitting: bool = false
var pinch_amount: float = 0.0
var target_pos: Vector2 = Vector2.ZERO
var global_vertices: Array = []
var velocities: Array = []
var food_in_range: Array = []
var external_force := Vector2.ZERO
var noise := FastNoiseLite.new()
var current_radius: float = 50.0
var signal_pulse: float = 0.0
var shared_target: Vector2 = Vector2.ZERO
var organism_level: int = 1
var is_mega_fused: bool = false
var mega_type: String = ""
var maturity: float = 0.0
var is_being_eaten: bool = false
var being_eaten_by: Node2D = null
var eaten_amount: float = 0.0
var digestion_time: float = 1.5

@onready var membrane: Polygon2D = $Polygon2D
@onready var nucleus: Polygon2D = $Nucleus

func _ready():
	add_to_group("cells")
	noise.seed = randi()
	target_pos = global_position
	
	metabolism = CellMetabolism.new()
	physics = CellPhysics.new()
	brain = CellBrain.new()
	evolution = CellEvolution.new()
	reproduction = CellReproduction.new()
	visuals = CellVisuals.new()
	interaction = CellInteraction.new()
	genetics = Genetics.new()
	
	_initialize_vertices()
	visuals.update_nucleus_shape(self)
	
	tree_exited.connect(_on_tree_exited)
	
	modulate = genetics.get_color()

func _initialize_vertices():
	for i in range(vertex_count):
		var angle = (PI * 2 / vertex_count) * i
		var pos = global_position + Vector2(cos(angle), sin(angle)) * current_radius
		global_vertices.append(pos)
		velocities.append(Vector2.ZERO)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_mouse_position().distance_to(global_position) < current_radius * 1.5:
				is_dragging = true
				get_viewport().set_input_as_handled()
		else:
			is_dragging = false

var logic_timer: float = 0.0
var age: float = 0.0
var maturation_age: float = 5.0

func _physics_process(delta: float):
	var time = Time.get_ticks_msec() * 0.001
	
	age += delta
	
	metabolism.update(self, delta)
	
	physics.apply_separation(self, delta)
	physics.apply_bond_physics(self, delta)
	physics.update_membrane(self, time, delta)
	
	if is_splitting:
		pinch_amount = move_toward(pinch_amount, 1.0, delta * 0.6)
		if pinch_amount >= 1.0:
			reproduction.complete_division(self)
	elif is_dragging:
		target_pos = get_global_mouse_position()
		global_position = global_position.lerp(target_pos, delta * 20.0)
	else:
		brain.decide_behavior(self, delta, time)
	
	if current_role == 5:
		interaction.update_eating(self, delta)
	
	global_position += external_force * delta
	external_force = external_force.lerp(Vector2.ZERO, delta * 5.0)
	
	visuals.update_membrane(self, time, delta)
	visuals.update_nucleus_visuals(self, delta, time)
	signal_pulse = move_toward(signal_pulse, 0.0, delta * 2.0)
	
	logic_timer += delta
	if logic_timer >= 2.0:
		evolution.check_evolution(self)
		logic_timer = 0.0
	
	queue_redraw()

func _draw():
	var time = Time.get_ticks_msec() * 0.001
	visuals.draw(self, time)

func _on_body_area_area_entered(area: Area2D):
	print("DEBUG: Body area entered: ", area.name, " in cell ", name)
	interaction.handle_area_entered(self, area)

func _on_sense_area_area_entered(area: Area2D):
	print("DEBUG: Sense area entered: ", area.name)
	interaction.handle_sense_entered(self, area)

func _on_sense_area_area_exited(area: Area2D):
	print("DEBUG: Sense area exited: ", area.name)
	interaction.handle_sense_exited(self, area)

func _on_tree_exited():
	for other in connected_cells:
		if is_instance_valid(other):
			other.connected_cells.erase(self)
	
	var waste_cloud = WasteCloud.get_instance()
	waste_cloud.add_waste(global_position, energy * 2.0)
