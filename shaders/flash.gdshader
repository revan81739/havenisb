shader_type canvas_item;
// Tints the sprite towards `flash_color`. flash_amount 0 = normal, 1 = solid color.
// The Player script creates the ShaderMaterial and drives these uniforms.

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);
}
