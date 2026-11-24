shader_type sky;

// V30 6-World Starry Nebula & Atmospheric Mist Sky Shader (fast, mobile GL Compatibility safe)
uniform vec3 sky_top : source_color = vec3(0.02, 0.04, 0.12);
uniform vec3 sky_horizon : source_color = vec3(0.10, 0.16, 0.30);
uniform vec3 nebula_color : source_color = vec3(0.18, 0.30, 0.48);
uniform vec3 star_color : source_color = vec3(0.92, 0.96, 1.0);
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.45;
uniform float star_density : hint_range(0.0, 1.0) = 0.65;

float hash31(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);
	float horizon_band = pow(1.0 - abs(d.y), 2.4);
	vec3 col = mix(sky_top, sky_horizon, horizon_band);

	// Soft layered nebula & drifting atmospheric mist clouds
	float n1 = noise3(d * 3.2 + vec3(0.0, TIME * 0.008, 0.0));
	float n2 = noise3(d * 6.8 - vec3(TIME * 0.006, 0.0, 0.0));
	float clouds = smoothstep(0.38, 0.82, n1 * 0.65 + n2 * 0.35);
	col += nebula_color * clouds * nebula_strength * (0.45 + 0.55 * horizon_band);

	// Crisp twinkling stars
	vec3 star_grid = floor(d * 190.0);
	float s = hash31(star_grid);
	float threshold = mix(0.996, 0.985, star_density);
	if (s > threshold) {
		float twinkle = 0.65 + 0.35 * sin(TIME * 2.2 + s * 90.0);
		float bright = smoothstep(threshold, 1.0, s) * twinkle;
		col += star_color * bright * 1.15;
	}

	COLOR = col;
}
