shader_type canvas_item;


uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float quant = 8.0;
render_mode unshaded;
uniform vec2 screenSize = vec2(288, 162);

void fragment() {
	
	vec4 newColor = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 screen = textureLod(screen_texture, SCREEN_UV, 0.0);
	
	for (int i = 0; i < 4; i++) {
		newColor[i] = screen[i] * quant;
		float f = fract(newColor[i]);
		
		float dith = round(1.0 / f);
		
		
		
		vec2 modo = vec2(
		mod(UV.x, (1.0 / screenSize.x) * dith) * screenSize.x,
		mod(UV.y, (1.0 / screenSize.y) * dith) * screenSize.y);
		modo.x = round(modo.x);
		modo.y = round(modo.y);
		
		if (f > ceil(modo.x + modo.y) ) {
			f = 1.0;
		}
		else {
			f = 0.0;
		}
		newColor[i] = floor(newColor[i]) + f;
		newColor[i] /= quant;
		}
		
	
	COLOR = newColor;
}