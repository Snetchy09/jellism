extends Node2D
class_name BiomeField

var background_rect: ColorRect
var waste_rect: ColorRect
@export var detail_scale: float = 15.0

func _ready():
	z_index = -100
	_create_background()
	_create_waste_layer()

func _create_background():
	var canvas = CanvasLayer.new()
	canvas.layer = -100
	add_child(canvas)
	
	background_rect = ColorRect.new()
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background_rect)
	
	var mat = ShaderMaterial.new()
	mat.shader = _get_shader()
	background_rect.material = mat

func _create_waste_layer():
	var canvas = CanvasLayer.new()
	canvas.layer = -99
	add_child(canvas)
	
	waste_rect = ColorRect.new()
	waste_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(waste_rect)

func _process(_delta):
	var cam = get_viewport().get_camera_2d()
	if cam:
		background_rect.material.set_shader_parameter("cam_pos", cam.global_position)
		background_rect.material.set_shader_parameter("zoom", cam.zoom.x)
		_update_waste_display(cam)

func _update_waste_display(cam: Camera2D):
	waste_rect.queue_redraw()
	
	if not waste_rect.get_canvas_item():
		return
	
	var waste_cloud = WasteCloud.get_instance()
	var cam_pos = cam.global_position
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = cam.zoom.x
	
	for grid_pos in waste_cloud.waste_map.keys():
		var waste_amount = waste_cloud.waste_map[grid_pos]
		if waste_amount <= 0:
			continue
		
		var screen_pos = (grid_pos - cam_pos) * zoom + viewport_size * 0.5
		var cell_size = waste_cloud.waste_cell_size * zoom
		
		if screen_pos.x + cell_size < 0 or screen_pos.x > viewport_size.x:
			continue
		if screen_pos.y + cell_size < 0 or screen_pos.y > viewport_size.y:
			continue
		
		var color = waste_cloud.get_waste_color(waste_amount)
		var rect = Rect2(screen_pos, Vector2.ONE * cell_size)
		
		waste_rect.draw_rect(rect, color)

static func get_biome_influence(pos: Vector2) -> float:
	return randf()

func _get_shader() -> Shader:
	var shader = Shader.new()
	shader.code = "shader_type canvas_item;uniform vec2 cam_pos;uniform float zoom;vec2 hash(vec2 p) {p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);}float noise(vec2 p) {vec2 i = floor(p); vec2 f = fract(p);vec2 u = f*f*(3.0-2.0*f);return mix(mix(dot(hash(i + vec2(0,0)), f - vec2(0,0)), dot(hash(i + vec2(1,0)), f - vec2(1,0)), u.x), mix(dot(hash(i + vec2(0,1)), f - vec2(0,1)), dot(hash(i + vec2(1,1)), f - vec2(1,1)), u.x), u.y);}void fragment() {vec2 world_uv = (SCREEN_UV - 0.5) / zoom + (cam_pos * 0.001);vec2 uv = world_uv * 2.0;float t = TIME * 0.1;float n = noise(uv + t);n += 0.5 * noise(uv * 2.0 - t * 0.5);float dist = distance(SCREEN_UV, vec2(0.5));vec3 col;col.r = 0.1 + 0.2 * noise(uv + n + 0.01);col.g = 0.15 + 0.2 * noise(uv + n);col.b = 0.2 + 0.3 * noise(uv + n - 0.01);col *= smoothstep(0.8, 0.3, dist);if (noise(uv * 50.0) > 0.48) col += 0.03;COLOR = vec4(col, 1.0);}"
	return shader
