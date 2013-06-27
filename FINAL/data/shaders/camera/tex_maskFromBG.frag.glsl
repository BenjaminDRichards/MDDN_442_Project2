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


uniform sampler2D background;
uniform float bgThreshold;


void main()
{
	vec4 bgCol = texture2D(background, vertTexCoord.xy);
	vec4 fgCol = texture2D(texture, vertTexCoord.xy);
	vec4 dFgBg = bgCol - fgCol;
	
	float dR = abs(dFgBg.r);
	float dG = abs(dFgBg.g);
	float dB = abs(dFgBg.b);
	float sumDiff = (dR + dG + dB) / 3.0;
	
	vec4 outCol = vec4(1.0, 1.0, 1.0, 1.0);
	if(sumDiff < bgThreshold)
	{
		outCol = vec4(0.0, 0.0, 0.0, 1.0);
	}
	
	gl_FragColor = outCol * vertColor;
}