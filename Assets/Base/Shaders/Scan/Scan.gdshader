shader_type canvas_item;

render_mode unshaded;

uniform float split = 16.0;
uniform float speed = 8.0;

void fragment() {
	float yValue = mod(UV.y, 0.5) * 2.0;
	yValue = abs(yValue - UV.y) * 2.0;
	/*
	yValue -= clamp(pow(UV.x, 2.0) * 2.0, 0, 1);
	*/
	float triangle = clamp((yValue + UV.x) - 1.0, 0, 1);
	triangle *= sin(pow(yValue, yValue) * PI * 0.5);
	
	float resolution = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
	float newSplit = split / resolution;
	
	float bars = round(mod((UV.x + sin(-pow(yValue, 0.5) * PI * 0.5)) + (TIME / speed), 3.0 / newSplit) * 0.25 * newSplit);
	
	float val = pow(triangle * bars, 0.5);
	
	COLOR = vec4(val, val, val, val);
}