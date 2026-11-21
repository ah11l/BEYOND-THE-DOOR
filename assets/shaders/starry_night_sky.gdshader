shader_type sky;

uniform vec3 top_color : source_color = vec3(0.035, 0.055, 0.145);
uniform vec3 horizon_color : source_color = vec3(0.24, 0.14, 0.36);
uniform vec3 bottom_color : source_color = vec3(0.11, 0.08, 0.24);
uniform vec3 glow_tint : source_color = vec3(0.45, 0.22, 0.52);
uniform float star_density : hint_range(0.0, 1.0) = 0.65;

float hash31(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = clamp(dir.y, -1.0, 1.0);

	vec3 col;
	if (up >= 0.0) {
		float t = pow(up, 0.55);
		col = mix(horizon_color, top_color, t);
	} else {
		float t = pow(-up, 0.65);
		col = mix(horizon_color, bottom_color, t);
	}

	// Subtle purple-pink horizon nebula band matching the visual reference
	float band = exp(-pow((dir.y + 0.06) * 4.2, 2.0));
	float side_glow = 0.5 + 0.5 * sin(dir.x * 2.2 - dir.z * 1.4);
	col += glow_tint * band * side_glow * 0.28;

	// Crisp procedural stars in upper hemisphere
	if (dir.y > -0.15) {
		vec3 grid = floor(dir * 185.0);
		float h = hash31(grid);
		if (h > (1.0 - 0.014 * star_density)) {
			float twinkle = 0.65 + 0.35 * sin(TIME * (1.2 + h * 3.0) + h * 40.0);
			float fade = smoothstep(-0.12, 0.25, dir.y);
			col += vec3(0.85, 0.90, 1.0) * twinkle * fade * 0.85;
		}
	}

	COLOR = col;
}
