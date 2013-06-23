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


float screenChannel(float base, float app)
{
	return( 1.0 - (1.0 - base) * (1.0 - app) );
}


void main()
{
	vec4 maskCol = texture2D(fgMask, vertTexCoord.xy);
	vec4 feedCol = texture2D(texture, vertTexCoord.xy);
	
	gl_FragColor = vec4(screenChannel(feedCol.r, maskCol.r),
						screenChannel(feedCol.g, maskCol.g),
						screenChannel(feedCol.b, maskCol.b),
						1.0);
}