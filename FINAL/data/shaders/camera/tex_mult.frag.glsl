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


void main()
{
	vec4 maskCol = texture2D(fgMask, vertTexCoord.xy);
	vec4 feedCol = texture2D(texture, vertTexCoord.xy);
	vec4 mult = maskCol * feedCol;
	
	gl_FragColor = vec4(mult.rgb, 1.0);
}