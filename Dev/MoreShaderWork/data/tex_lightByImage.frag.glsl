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

// External map data
uniform sampler2D normalMap;
uniform sampler2D lightSpecularMap;
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
	
	if(0 < surfaceVec.a )
	{
		// Derive specular data
		float specularStrength = texture2D(lightSpecularMap, mapCoord).x;
		
		// Light vector and intensity are derived from texture
		vec4 lightVec = texture2D(texture, vertTexCoord.xy) * normalScalar + normalAdder;
		float lightIntensity = lightVec.a * lightBrightness;
		
		// Derive diffuse lighting
		float diffValue = max( dot( lightVec, surfaceVec.xyz ),  0.0 ) * lightIntensity;
		
		// Compute reflection vectors
		vec3 reflectionVec = reflect(-lightVec, surfaceVec);
		float eyeDot = max( dot(reflectionVec, eyeVec),  0.0);	// Clamped to avoid negatives
		
		// Compute specular power
		float specular = pow(eyeDot, lightSpecularPower) * specularStrength * lightIntensity;
		
		// Composit color
		float value = diffValue + specular;
		vec4 outCol = vec4(value, value, value, value) * lightColor;
		gl_FragColor = outCol;
		// Note that, for this to display correctly, the blendFunc must be ONE, ONE
	}
}