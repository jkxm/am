shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float vignette_inner : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_outer : hint_range(0.0, 1.5) = 0.9;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);

uniform float aberration_amount : hint_range(0.0, 0.03) = 0.0;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

void fragment() {
	vec2 uv = SCREEN_UV;

	float r = texture(screen_tex, uv + vec2(aberration_amount, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(aberration_amount, 0.0)).b;
	vec3 color = vec3(r, g, b);

	float dist = distance(uv, vec2(0.5));
	float vig = smoothstep(vignette_inner, vignette_outer, dist) * vignette_intensity;
	color = mix(color, vignette_color.rgb, vig);

	color = mix(color, flash_color.rgb, flash_color.a);

	COLOR = vec4(color, 1.0);
}
