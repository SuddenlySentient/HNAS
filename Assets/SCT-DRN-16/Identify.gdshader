shader_type canvas_item;

render_mode unshaded;
render_mode blend_mix;
uniform float quant = 8.0;
uniform float split = 8.0;
uniform float speed = -5.0;
uniform float waveSpeed = 1.5;
uniform float lines = 2.5;
uniform vec4 hue1 : source_color;
uniform sampler2D screen_texture : hint_screen_texture;



void vertex() {
	VERTEX.x = abs(VERTEX.x - (VERTEX.y / 2.0));
	VERTEX.y = 256.0 -VERTEX.y;
}


void fragment() {
	
	//COLOR = vec4((4.0 * UV.y));
	
	COLOR = texture(screen_texture, SCREEN_UV);
	
	float wavy = UV.y;
	int times = 2;
	for (int i = 0; i <= times; i++) {
		wavy += sin((UV.x * PI + (TIME * waveSpeed)) * float(i)) / (16.0 * float(times));
		}
	float scan = (mod(wavy + (TIME * (1.0 / speed)), (1.0 * split / lines) / split) * split);
	scan = clamp((scan / 4.0) - (1.0 / lines), 0, 1) * lines;
	COLOR += hue1;
	COLOR = vec4(COLOR.rgb, scan + 0.125);
	COLOR.a = (COLOR.a + 0.125) * pow(2.0 * UV.y, 2.0);
	COLOR.a *= hue1.a;
}