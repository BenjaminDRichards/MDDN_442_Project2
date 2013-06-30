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


uniform vec2 resolution;


vec4 threshold(vec4 col)
{
	if(col.r < 0.5)
	{
		return( vec4(0.0, 0.0, 0.0, 0.0) );
	}
	return( vec4(1.0, 1.0, 1.0, 0.2) );
}


void main() {
	vec2 intCoord = vec2( float( int( vertTexCoord.x * resolution.x ) ),
							float( int( vertTexCoord.y * resolution.y ) ) );
	vec2 intProbe = intCoord / resolution;
	vec4 probeCol = threshold( texture2D(texture, intProbe) );
	
	// Probe for neighbours
	vec2 intCoordY = intCoord + vec2(0.0, -1.0);
	vec4 yCol = threshold( texture2D(texture, intCoordY / resolution) );
	vec2 intCoordX = intCoord + vec2(1.0, 0.0);
	vec4 xCol = threshold( texture2D(texture, intCoordX / resolution) );
	
	// Examine neighbours
	if( probeCol.r != yCol.r )
	{
		// Difference
		if( abs(intProbe.y - vertTexCoord.y) < 0.1 / resolution.y )
		{
			probeCol = vec4(1.0, 1.0, 1.0, 1.0);
		}
	}
	if( probeCol.r != xCol.r )
	{
		// Difference
		if( abs(intProbe.x - vertTexCoord.x) < 0.05 / resolution.y )
		{
			probeCol = vec4(1.0, 1.0, 1.0, 1.0);
		}
	}
	
	gl_FragColor = probeCol * vertColor;
}