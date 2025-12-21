extends Camera2D

var target_zoom: float = 1.0
var zoom_speed: float = 10.0
var min_zoom: float = 0.2
var max_zoom: float = 2.0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom + 0.1, min_zoom, max_zoom)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom - 0.1, min_zoom, max_zoom)

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		position -= event.relative / zoom # Pan relative to zoom level

func _process(delta):
	zoom = zoom.lerp(Vector2.ONE * target_zoom, delta * zoom_speed)
