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


uniform sampler2D texture2;


void main() {
	vec4 one = vec4(1.0, 1.0, 1.0, 1.0);
	gl_FragColor = (	one - ( one - texture2D(texture2, vertTexCoord.xy) )
						* ( one - texture2D(texture, vertTexCoord.xy) ) ) * vertColor;
}