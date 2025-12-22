extends Node2D
class_name BiomeField

var background_rect: ColorRect
@export var detail_scale: float = 15.0 # Match your 'UV * 15.0'

func _ready():
	z_index = -100
	_create_background()

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

func _process(_delta):
	var cam = get_viewport().get_camera_2d()
	if cam:
		background_rect.material.set_shader_parameter("cam_pos", cam.global_position)
		background_rect.material.set_shader_parameter("zoom", cam.zoom.x)

# THIS IS THE INTERACTIVE PART: 
# Any script can call: BiomeField.get_biome_at(position)
static func get_biome_influence(pos: Vector2) -> float:
	# We use a simple noise here that mimics the shader's 'n' value
	# You can use a FastNoiseLite property here to match perfectly
	return randf() # Placeholder: Replace with noise calculation if needed

func _get_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform vec2 cam_pos;
	uniform float zoom;

	vec2 hash(vec2 p) {
		p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
		return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
	}

	float noise(vec2 p) {
		vec2 i = floor(p); vec2 f = fract(p);
		vec2 u = f*f*(3.0-2.0*f);
		return mix(mix(dot(hash(i + vec2(0,0)), f - vec2(0,0)), 
		               dot(hash(i + vec2(1,0)), f - vec2(1,0)), u.x),
		           mix(dot(hash(i + vec2(0,1)), f - vec2(0,1)), 
		               dot(hash(i + vec2(1,1)), f - vec2(1,1)), u.x), u.y);
	}

	void fragment() {
		// FIXED WORLD COORDS
		vec2 world_uv = (SCREEN_UV - 0.5) / zoom + (cam_pos * 0.001);
		vec2 uv = world_uv * 2.0; 
		float t = TIME * 0.1;
		
		float n = noise(uv + t);
		n += 0.5 * noise(uv * 2.0 - t * 0.5);
		
		// VIGNETTE STAYS STUCK TO SCREEN
		float dist = distance(SCREEN_UV, vec2(0.5));
		
		vec3 col;
		col.r = 0.1 + 0.2 * noise(uv + n + 0.01);
		col.g = 0.15 + 0.2 * noise(uv + n);
		col.b = 0.2 + 0.3 * noise(uv + n - 0.01);
		
		col *= smoothstep(0.8, 0.3, dist); // Use SCREEN_UV dist
		
		if (noise(uv * 50.0) > 0.48) col += 0.03;
		
		COLOR = vec4(col, 1.0);
	}
	"""
	return shader
