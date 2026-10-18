shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 source = texture(screen_texture, uv).rgb;
	// Restrained ordered grain and reduced color precision, at the native 640x360.
	vec2 pixel = floor(FRAGCOORD.xy);
	float checker = mod(pixel.x + mod(pixel.y, 2.0), 2.0) - 0.5;
	float grain = fract(sin(dot(pixel + floor(TIME * 12.0), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	source = floor(max(source + checker / 85.0 + grain / 180.0, vec3(0.0)) * 48.0 + 0.5) / 48.0;
	vec2 edge = uv * (1.0 - uv);
	float vignette = clamp(pow(edge.x * edge.y * 16.0, 0.24), 0.4, 1.0);
	COLOR = vec4(source * vignette, 1.0);
}
