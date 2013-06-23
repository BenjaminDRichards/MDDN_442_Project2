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


uniform sampler2D fgMask;

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
	// Get heat samples
	vec4 h00 = texture2D(texture, vertTexCoord.xy + b00 * blurStep);
	vec4 h10 = texture2D(texture, vertTexCoord.xy + b10 * blurStep);
	vec4 h20 = texture2D(texture, vertTexCoord.xy + b20 * blurStep);
	
	vec4 h01 = texture2D(texture, vertTexCoord.xy + b01 * blurStep);
	vec4 h11 = texture2D(texture, vertTexCoord.xy + b11 * blurStep);
	vec4 h21 = texture2D(texture, vertTexCoord.xy + b21 * blurStep);
	
	vec4 h02 = texture2D(texture, vertTexCoord.xy + b02 * blurStep);
	vec4 h12 = texture2D(texture, vertTexCoord.xy + b12 * blurStep);
	vec4 h22 = texture2D(texture, vertTexCoord.xy + b22 * blurStep);
	
	// Average heat samples
	vec4 heat = (h00 + h10 + h20 + h01 + h11 + h21 + h02 + h12 + h22) / samples;
	
	// Get mask
	vec4 mask = texture2D(fgMask, vertTexCoord.xy);
	
	
	gl_FragColor = vec4(heat.rgb - mask.rgb, 1.0);
}