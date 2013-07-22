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



// Light data
uniform float lightSpecularPower;
uniform vec4 lightColor;
uniform float lightBrightness;
uniform float lightSpecularFactor;

// External map data
uniform sampler2D normalMap;
uniform sampler2D lightSpecularMap;
// World rotation for transforming lights
uniform float worldAngle;
// Remap from this transform to the map space
// This relies on unrotated assets
uniform vec2 mapCoordScale;
uniform vec2 mapCoordOffset;

// Eye vector is always perpendicular to view plane
const vec3 eyeVec = vec3(0.0, 0.0, 1.0);
// Normal remap scalar
const vec4 normalScalar = vec4(2.0, 2.0, 2.0, 1.0);
// Normal remap addition
const vec4 normalAdder = vec4(-1.0, -1.0, -1.0, 0.0);



void main() {
	// Derive normal data
	// Remap coordinates to map space
	vec2 mapCoord = vertTexCoord.xy * mapCoordScale + mapCoordOffset;
	// Remap from 0,1 to -1,1
	vec4 surfaceVec = (texture2D(normalMap, mapCoord) * normalScalar) + normalAdder;
	
	if(0.0 < surfaceVec.a )
	{
		// Derive specular data
		float specularStrength = texture2D(lightSpecularMap, mapCoord).x;
		
		// Light vector and intensity are derived from texture
		vec4 lightVec = texture2D(texture, vertTexCoord.xy) * normalScalar + normalAdder;
		float lightIntensity = lightVec.a * lightBrightness;
		
		// Do not rotate lights without better mapCoord mathematics
		/*
		// Counter-rotate light vector
		float x = lightVec.x;
		float y = lightVec.y;
		
		float derivedAngle = atan(y, x) - worldAngle;
		float d = length( vec2(x, y) );
		x = cos(derivedAngle) * d;
		y = sin(derivedAngle) * d;
	
		lightVec = vec4(x, y, lightVec.z, lightVec.a);
		*/
		
		// Derive diffuse lighting
		float diffValue = max( dot( lightVec.xyz, surfaceVec.xyz ),  0.0 ) * lightIntensity;
		
		// Compute reflection vectors
		vec3 reflectionVec = reflect(-lightVec.xyz, surfaceVec.xyz);
		float eyeDot = max( dot(reflectionVec, eyeVec),  0.0);	// Clamped to avoid negatives
		
		// Compute specular power
		float specular = pow(eyeDot, lightSpecularPower)
			* specularStrength * lightIntensity * lightSpecularFactor;
		
		// Composit color
		gl_FragColor = vec4(diffValue + specular) * lightColor;
		// Note that, for this to display correctly, the blendFunc must be ONE, ONE
	}
}