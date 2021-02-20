shader_type canvas_item;

uniform float FREQ = 180.0;
uniform int OCTAVES = 4;

uniform float MOTION_FREQ = 180.0;
uniform int MOTION_OCTAVES = 2;
uniform float MOTION_SPEED = 0.5;

uniform float RATIO = 0.5;
uniform float RESOLUTION = 10.0;
uniform float ALPHA = 0.5;
uniform vec3 color = vec3(0.22, 0.24, 0.36);

float rand(vec2 coord){
	return fract(sin(dot(coord, vec2(21, 53))*1000.0)*1000.0);
}

vec2 quantize(vec2 v, float r){
	return floor(v*r)/r;
}

float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = coord - i;
	
	float a  = rand(i);
	float b  = rand(i + vec2(1.0, 0.0));
	float c  = rand(i + vec2(1.0, 1.0));
	float d  = rand(i + vec2(0.0, 1.0));
	
	return mix(a, b, f.x) + (d - a) * f.y * (1.0 - f.x) + (c - b) * f.x * f.y;
}

float fbm(vec2 coord, int octs){
	float value = 0.0;
	float scale = 0.5;
	
	for(int i = 0; i < octs; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= RATIO;
	}
	
	return value;
}

void fragment(){
	vec2 QUV = quantize(UV, RESOLUTION);
	vec2 coord = QUV*FREQ;
	vec2 motion = vec2(fbm(QUV*MOTION_FREQ + TIME*MOTION_SPEED, MOTION_OCTAVES));
	float value = fbm(coord + motion, OCTAVES);
	COLOR = vec4(color, value*ALPHA);
}

