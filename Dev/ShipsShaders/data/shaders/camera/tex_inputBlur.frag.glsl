#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

// Begin standard Processing assets
uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;
// End standard Processing assets


uniform vec2 blurStep;			// Aspect ratio-corrected


// Blur vectors
vec2 b00 = vec2(-1.0, -1.0);
vec2 b10 = vec2(0.0, -1.0);
vec2 b20 = vec2(1.0, -1.0);

vec2 b01 = vec2(-1.0, 0.0);
vec2 b11 = vec2(0.0, 0.0);
vec2 b21 = vec2(1.0, 0.0);

vec2 b02 = vec2(-1.0, 1.0);
vec2 b12 = vec2(0.0, 1.0);
vec2 b22 = vec2(1.0, 1.0);

float samples = 9.0;


void main()
{
	// Get input samples
	vec4 c00 = texture2D(texture, vertTexCoord.xy + b00 * blurStep);
	vec4 c10 = texture2D(texture, vertTexCoord.xy + b10 * blurStep);
	vec4 c20 = texture2D(texture, vertTexCoord.xy + b20 * blurStep);
	
	vec4 c01 = texture2D(texture, vertTexCoord.xy + b01 * blurStep);
	vec4 c11 = texture2D(texture, vertTexCoord.xy + b11 * blurStep);
	vec4 c21 = texture2D(texture, vertTexCoord.xy + b21 * blurStep);
	
	vec4 c02 = texture2D(texture, vertTexCoord.xy + b02 * blurStep);
	vec4 c12 = texture2D(texture, vertTexCoord.xy + b12 * blurStep);
	vec4 c22 = texture2D(texture, vertTexCoord.xy + b22 * blurStep);
	
	// Average samples
	vec4 sum = (c00 + c10 + c20 + c01 + c11 + c21 + c02 + c12 + c22) / samples;
	
	gl_FragColor = sum * vertColor;
}