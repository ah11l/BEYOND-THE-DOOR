shader_type sky;

uniform vec3 top_color : source_color = vec3(0.04, 0.06, 0.16);
uniform vec3 horizon_color : source_color = vec3(0.18, 0.14, 0.34);
uniform vec3 bottom_color : source_color = vec3(0.10, 0.08, 0.24);
uniform vec3 blue_glow : source_color = vec3(0.08, 0.44, 0.78);
uniform vec3 rose_glow : source_color = vec3(0.56, 0.22, 0.40);

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = clamp(dir.y, -1.0, 1.0);

	vec3 col = up >= 0.0
		? mix(horizon_color, top_color, pow(up, 0.55))
		: mix(horizon_color, bottom_color, pow(-up, 0.65));

	// Reference dual-tone atmospheric glow: cyan-blue right/upper, warm rose-pink left/lower
	float right_glow = smoothstep(-0.2, 0.9, dir.x) * smoothstep(-0.5, 0.5, dir.y);
	float left_glow = smoothstep(-0.2, 0.9, -dir.x) * smoothstep(0.45, -0.55, dir.y);
	col += blue_glow * right_glow * 0.48;
	col += rose_glow * left_glow * 0.44;

	// Crisp, clearly visible stars on mobile screens
	vec2 uv = vec2(atan(dir.x, dir.z) / 6.28318 + 0.5, asin(clamp(dir.y, -1.0, 1.0)) / 3.14159 + 0.5);
	vec2 grid_uv = uv * vec2(96.0, 48.0);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv) - 0.5;
	float h = hash21(cell);
	if (h > 0.92 && dir.y > -0.25) {
		vec2 offset = (vec2(hash21(cell + 1.3), hash21(cell + 7.1)) - 0.5) * 0.6;
		float d = length(f - offset);
		float star_r = mix(0.055, 0.125, fract(h * 17.3));
		float star = smoothstep(star_r, 0.0, d);
		float twinkle = 0.72 + 0.28 * sin(TIME * (1.5 + h * 4.0) + h * 60.0);
		col += vec3(0.92, 0.96, 1.0) * star * twinkle * 1.15;
	}

	COLOR = col;
}
