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


const vec4 energyVec = vec4(0.8, 0.9, 1.0, 1.0);


void main() {
	// Probe surroundings
	vec4 sumCol = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 maxCol = vec4(0.0, 0.0, 0.0, 1.0);
	float distSum = 0.0;
	for(float x = -bloomSteps.x;  x <= bloomSteps.x;  x+=1.0)
	{
		for(float y = -bloomSteps.y;  y <= bloomSteps.y;  y+=1.0)
		{
			vec2 cursor = vec2( clamp(vertTexCoord.x + x * bloomDist.x, 0.0, 1.0),
								clamp(vertTexCoord.y + y * bloomDist.y, 0.0, 1.0) );
			float distX = 0.0;
			if(bloomSteps.x != 0.0)	{	distX = x / bloomSteps.x;	}
			float distY = 0.0;
			if(bloomSteps.y != 0.0)	{	distY = y / bloomSteps.y;	}
			float distFactor = 1.0 / (sqrt( pow(distX, 2.0)
											+ pow(distY, 2.0) ) + 1.0);
			
			vec4 probeCol = texture2D(texture, cursor.xy) * distFactor;
			
			// Get maximum lumosity
			maxCol = max(maxCol, probeCol);
			
			// Add to sum buffer
			sumCol += probeCol;
			distSum += distFactor;
		}
	}
	
	//sumCol = sumCol / distSum;
	//maxCol = maxCol * 0.5 + sumCol;
	//maxCol = mix( maxCol, sumCol, length(sumCol) * 0.5 );
	
	//maxCol = ( maxCol + (sumCol / distSum) ) * energyVec * 0.5;
	maxCol = max( maxCol, sumCol / distSum ) * energyVec;
	
	maxCol = vec4(
					pow(maxCol.r, bloomFallPower),
					pow(maxCol.g, bloomFallPower),
					pow(maxCol.b, bloomFallPower),
					pow(maxCol.a, bloomFallPower) );
	
	gl_FragColor = maxCol * vertColor;
}