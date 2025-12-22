extends Camera2D

var target_zoom: float = 1.0
var zoom_speed: float = 10.0
var min_zoom: float = 0.2
var max_zoom: float = 2.0

var pan_speed: float = 600.0
var pan_accel: float = 8.0
var pan_decel: float = 6.0
var drag_pan_sensitivity: float = 1.0

var _velocity: Vector2 = Vector2.ZERO
var _target_position: Vector2

func _ready():
	_target_position = global_position

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom = clamp(target_zoom + 0.1, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom = clamp(target_zoom - 0.1, min_zoom, max_zoom)

	# Mouse drag panning (right mouse button)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# Move camera opposite to mouse movement, scaled by zoom
		_target_position -= event.relative * drag_pan_sensitivity * (1.0 / zoom.x)

func _process(delta):
	# Smooth zoom
	zoom = zoom.lerp(Vector2.ONE * target_zoom, delta * zoom_speed)

	# Keyboard panning (WASD / arrow keys)
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1.0
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1.0

	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		var boost := 1.5 if Input.is_action_pressed("ui_focus_next") else 1.0 # Shift by default
		var target_vel := input_dir * pan_speed * boost * (1.0 / zoom.x)
		_velocity = _velocity.lerp(target_vel, pan_accel * delta)
	else:
		_velocity = _velocity.lerp(Vector2.ZERO, pan_decel * delta)

	_target_position += _velocity * delta
	global_position = global_position.lerp(_target_position, 1.0 - exp(-pan_accel * delta))
