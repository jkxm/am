shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float dither_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	int x = int(FRAGCOORD.x) % 4;
	int y = int(FRAGCOORD.y) % 4;
	int index = x + y * 4;

	float bayer[16] = float[16](
		 0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
		12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
		 3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
		15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
	);

	float threshold = bayer[index];

	if (dither_amount > threshold) {
		discard;
	}

	ALBEDO = albedo_color.rgb;
	ROUGHNESS = roughness;
}
