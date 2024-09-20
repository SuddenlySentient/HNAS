shader_type canvas_item;

uniform float quant = 8.0;
uniform float lightValue = 1.0;
/*render_mode unshaded;*/



void fragment() {
	
	vec4 newColor = vec4(0.0, 0.0, 0.0, 0.0);
	
	for (int i = 0; i < 4; i++) {
		newColor[i] = COLOR[i] * quant;
		float f = fract(newColor[i]);
		
		float dith = round(1.0 / f);
		
		vec2 modo = vec2(
		mod(UV.x, TEXTURE_PIXEL_SIZE.x * dith) * (0.5 / TEXTURE_PIXEL_SIZE.x),
		mod(UV.y, TEXTURE_PIXEL_SIZE.y * dith) * (0.5 / TEXTURE_PIXEL_SIZE.y));
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

uniform float lightQuant = 8.0;

void light() {
	
	vec4 newColor = vec4(0.0, 0.0, 0.0, 0.0);
	
	for (int i = 0; i < 4; i++) {
		newColor[i] = LIGHT_COLOR[i] * lightQuant;
		float f = fract(newColor[i]);
		
		float dith = round(1.0 / f);
		
		vec2 modo = vec2(
		mod(UV.x, TEXTURE_PIXEL_SIZE.x * dith) * (0.5 / TEXTURE_PIXEL_SIZE.x),
		mod(UV.y, TEXTURE_PIXEL_SIZE.y * dith) * (0.5 / TEXTURE_PIXEL_SIZE.y));
		modo.x = round(modo.x);
		modo.y = round(modo.y);
		
		if (f > ceil(modo.x + modo.y) ) {
			f = 1.0;
		}
		else {
			f = 0.0;
		}
		newColor[i] = floor(newColor[i]) + f;
		newColor[i] /= lightQuant;
		}
		
	
	LIGHT = COLOR * (newColor * LIGHT_ENERGY * lightValue);
}