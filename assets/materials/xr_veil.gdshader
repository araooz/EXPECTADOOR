shader_type spatial;
// Velo blanco en VR (resplandor ante la puerta y blanco final). En VR la capa
// 2D del Hud no se ve, así que el velo es un quad pegado a la cámara.
// Se dibuja antes del tonemapping: white_level = 6 coincide con tonemap_white,
// de modo que el blanco sale puro. Tras el cruce el entorno pasa a tonemapping
// lineal y white_level baja a 1 para que la huella conserve su contraste.
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled, depth_draw_never, depth_test_disabled, fog_disabled;

uniform float alpha : hint_range(0.0, 1.0) = 0.0;
uniform float white_level = 6.0;

void fragment() {
	ALBEDO = vec3(white_level);
	ALPHA = alpha;
}
