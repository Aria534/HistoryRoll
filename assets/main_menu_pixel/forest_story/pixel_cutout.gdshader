shader_type canvas_item;
render_mode unshaded;

uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.6;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (pixel.a < alpha_cutoff) {
		discard;
	}
	// Crisp pixel silhouettes, while retaining parent fades and button tinting.
	COLOR = vec4(pixel.rgb, 1.0) * sprite_tint;
}
