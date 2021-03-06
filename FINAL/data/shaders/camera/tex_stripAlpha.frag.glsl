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
	gl_FragColor = vec4(texture2D(texture, vertTexCoord.xy).rgb, 1.0);
}