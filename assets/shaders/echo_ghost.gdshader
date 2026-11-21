shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 core_color : source_color = vec4(0.18, 0.82, 1.0, 0.42);
uniform vec4 rim_color : source_color = vec4(0.62, 0.96, 1.0, 0.92);
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.4;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.6;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	vec3 col = mix(core_color.rgb, rim_color.rgb, fresnel) * pulse;
	float alpha = clamp(mix(core_color.a, rim_color.a, fresnel), 0.18, 0.92);
	ALBEDO = col;
	ALPHA = alpha;
}
