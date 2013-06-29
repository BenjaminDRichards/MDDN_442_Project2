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


uniform float bloomFallPower;
uniform vec2 bloomSteps;
uniform vec2 bloomDist;


void main() {
	// Probe surroundings
	vec4 sumCol = vec4(0.0, 0.0, 0.0, 1.0);
	float distSum = 0.0;
	for(float x = -bloomSteps.x;  x <= bloomSteps.x;  x+=1.0)
	{
		for(float y = -bloomSteps.y;  y <= bloomSteps.y;  y+=1.0)
		{
			vec2 cursor = vec2( clamp(vertTexCoord.x + x * bloomDist.x, 0.0, 1.0),
								clamp(vertTexCoord.y + y * bloomDist.y, 0.0, 1.0) );
			float distX = 0.0;
			if(x != 0)	{	distX = x / bloomSteps.x;	}
			float distY = 0.0;
			if(y != 0)	{	distY = y / bloomSteps.y;	}
			float distFactor = 1.0 / (sqrt( pow(distX, 2.0)
											+ pow(distY, 2.0) ) + 1.0);
			sumCol += texture2D(texture, cursor.xy) * distFactor;
			distSum += distFactor;
		}
	}
	
	//float samples = (bloomSteps.x * 2.0 + 1.0) * (bloomSteps.y * 2.0 + 1.0);
	sumCol *= vec4(0.9, 0.95, 1.0, 1.0);
	sumCol = (2.0 * sumCol) - (0.5 * distSum);
	sumCol = vec4(
					pow(sumCol.r / distSum, bloomFallPower),
					pow(sumCol.g / distSum, bloomFallPower),
					pow(sumCol.b / distSum, bloomFallPower),
					1.0
					);
	
	gl_FragColor = sumCol * vertColor;
}