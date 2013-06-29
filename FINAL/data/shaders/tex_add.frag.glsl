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
	gl_FragColor = ( texture2D(texture, vertTexCoord.xy) + texture2D(texture2, vertTexCoord.xy) ) * vertColor;
}