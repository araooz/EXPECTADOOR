shader_type spatial;
// La luz de la puerta: un punto circular que, al acercarse el espectador,
// se estira hasta tomar la forma rectangular del vano.
// Se dibuja con la distancia con signo a un rectángulo de esquinas redondeadas
// cuyo radio de esquina pasa del radio del punto (círculo) a cero (rectángulo).
render_mode unshaded, blend_mix, cull_back, shadows_disabled, depth_draw_never;

// 0 = punto, 1 = puerta.
uniform float shape : hint_range(0.0, 1.0) = 1.0;
// Aparición desde la oscuridad (0 = invisible, 1 = visible).
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
// Brillo por encima de 1: alimenta el halo (glow) del entorno.
uniform float energy = 3.0;
// Medidas en metros: mitad del vano y mitad del quad que contiene la forma.
uniform vec2 door_half_size = vec2(0.65, 1.2);
uniform vec2 quad_half_size = vec2(0.8, 1.3);
uniform float point_radius = 0.45;

float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + radius;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * quad_half_size;
	float s = smoothstep(0.0, 1.0, shape);
	vec2 half_size = mix(vec2(point_radius), door_half_size, s);
	float radius = mix(point_radius, 0.0, s);
	float d = rounded_box(p, half_size, radius);
	// Borde suave para el punto, nítido para la puerta.
	float edge = mix(0.08, 0.004, s);
	float mask = 1.0 - smoothstep(-edge, edge, d);
	ALBEDO = vec3(energy);
	ALPHA = mask * reveal;
}
