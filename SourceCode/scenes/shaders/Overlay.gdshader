// NOTE: Shader automatically converted from Godot Engine 3.4.4.stable's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform vec4 overlay_color : hint_color = vec4(0,0,0,1);


vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

void fragment()
{
	// image texture
	vec4 base = texture(TEXTURE, UV);
	// noise texture
	vec4 blend = overlay_color;
	
	COLOR = overlay(base, blend);
}