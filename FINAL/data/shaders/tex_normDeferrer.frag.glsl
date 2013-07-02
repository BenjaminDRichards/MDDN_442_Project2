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


// Normal remap scalar
const vec4 normalScalar = vec4(2.0, 2.0, 2.0, 1.0);
// Normal remap addition
const vec4 normalAdder = vec4(-1.0, -1.0, -1.0, 0.0);

// Rotation data
uniform float worldAngle;
uniform vec4 worldAngleFactor;


void main() {
	// Derive normal data, remap from 0,1 to -1,1
	vec4 normalMapValue = texture2D(texture, vertTexCoord.xy) * normalScalar + normalAdder;
	
	// Counter-rotate vector
	float derivedAngle = atan(normalMapValue.y, normalMapValue.x) - worldAngle;
	float d = length( normalMapValue.xy );
	
	// Remap back into 0,1
	gl_FragColor = ( ( vec4(cos(derivedAngle) * d,
							sin(derivedAngle) * d,
							normalMapValue.z, 
							normalMapValue.a ) - normalAdder) / normalScalar ) * vertColor;
}


/*
	// Expanded sequence
	
	// Derive normal data, remap from 0,1 to -1,1
	vec4 normalMapValue = texture2D(texture, vertTexCoord.xy) * normalScalar + normalAdder;
	
	// Counter-rotate vector
	float x = normalMapValue.x;
	float y = normalMapValue.y;
	
	//x = x * worldAngleFactor.x + y * worldAngleFactor.y;
	//y = x * worldAngleFactor.z + y * worldAngleFactor.w;
	
	float derivedAngle = atan(y, x) - worldAngle;
	float d = length( vec2(x, y) );
	x = cos(derivedAngle) * d;
	y = sin(derivedAngle) * d;
	
	//float ang = -worldAngle;
	//x = x * ( cos(ang) - sin(ang) );
	//y = y * ( sin(ang) + cos(ang) );

	normalMapValue = vec4(x, y, normalMapValue.z, normalMapValue.a);

	// Remap back into 0,1
	normalMapValue = (normalMapValue - normalAdder) / normalScalar;

	gl_FragColor = normalMapValue * vertColor;
*/
