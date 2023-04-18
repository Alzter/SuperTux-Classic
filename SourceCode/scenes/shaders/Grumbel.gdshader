shader_type canvas_item;
render_mode unshaded;


uniform float rainbow_speed : hint_range(-10,10) = 1.0;
uniform float displacement_strength : hint_range(0, 10.0) = 1.0;
uniform float noise_strength : hint_range(0, 10.0) = 0.75;
uniform float brightness_add : hint_range(-10.0, 10.0) = 0;
uniform float noise_shimmer_speed = 100.0;
uniform float color_shimmer_strength = 1.0;

void fragment() {
// Input:3
	vec3 input_color;
	
	vec2 uv = UV;
	
	float displace = (TIME + (UV.x / UV.y)) * 10.0;
	displace = mod(displace, 2.0f);
	displace = round(sin(displace)) * TEXTURE_PIXEL_SIZE.x;
	
	//float displace = sin((TIME + (UV.x / UV.y)) * 10f) * TEXTURE_PIXEL_SIZE.x;
	uv.x += displace * displacement_strength;
	uv.y += displace * -1.0 * displacement_strength;
	
	vec4 texture_color = texture(TEXTURE, uv);
	input_color = texture_color.rgb;

// VectorFunc:2
	vec3 color_hsv;
	{
		vec3 c = input_color;
		vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
		vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
		float d = q.x - min(q.w, q.y);
		float e = 1.0e-10;
		color_hsv=vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}
	
	float Shift_Hue = TIME * rainbow_speed;
	
	color_hsv.x = mod((color_hsv.x + Shift_Hue), 1.0f);
	
	float noise = tan(round(UV.x / TEXTURE_PIXEL_SIZE.x));
	noise += sin(round(UV.y / TEXTURE_PIXEL_SIZE.y));
	noise = mod(noise * 200.0, 30);
	noise /= sin(TIME * 20.0) * 1.0f;
	float noise_power = abs(sin(TIME * noise_shimmer_speed)) * noise_strength;
	noise *= noise_power;
	
	float noise2 = tan(TIME + (round(UV.x / TEXTURE_PIXEL_SIZE.x)) / (round(UV.y / TEXTURE_PIXEL_SIZE.y)));
	color_hsv.x += noise2 * color_shimmer_strength;
	
	color_hsv.z += sin(TIME + noise + noise2) * noise_power;
	
	color_hsv.z += brightness_add;

// VectorFunc:5
	vec3 color_rgb;
	{
		vec3 c = color_hsv;
		vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
		color_rgb=c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
	}

// Output:0
	texture_color = vec4(color_rgb.rgb,texture_color.a);
//
//	float alpha_noise = abs(sin(TIME * 10f) * 0.5f);
//	texture_color.a += color_hsv.z * alpha_noise;
	texture_color.a = clamp(texture_color.a, 0, 1);
	COLOR.rgba = texture_color;

}