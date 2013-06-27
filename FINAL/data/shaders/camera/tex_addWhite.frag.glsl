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


void main()
{
	float value = texture2D(texture, vertTexCoord.xy).r;
	
	gl_FragColor = vec4(value, value, value, value);
}