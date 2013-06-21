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


uniform vec2 resolution;			// Used to determine some scaling factors
// Light data
uniform sampler2D self;
uniform vec3 lightPosition;			// Please define this relative to the texture 
									// Because this is a full screen effect,
									// and light rotation is not an issue,
									// just map position into the (x:0,1, y:0,1) range
uniform float lightBrightness;
uniform float lightFalloffPower;
uniform float lightSpecularPower;
uniform float lightSpecularBlend;
uniform vec4 lightColor;

// Eye vector is always perpendicular to view plane
const vec3 eyeVec = vec3(0.0, 0.0, 1.0);
// Normal remap scalar
const vec4 normalScalar = vec4(2.0, 2.0, 2.0, 1.0);
// Normal remap addition
const vec4 normalAdder = vec4(-1.0, -1.0, -1.0, 0.0);


void main() {
	// Derive underlying color
	vec4 priorColor = texture2D(self, vertTexCoord.xy);
	
	// Derive light vector
	vec3 lightVec = lightPosition - vec3(vertTexCoord.xy, 0.0);
	
	// Derive light distance information
	// Correct for non-square draw regions
	float lightVecY2 = lightVec.y * resolution.y / resolution.x;
	lightVec = vec3(lightVec.x, lightVecY2, lightVec.z);
	float dist = length(lightVec);
	float intensity = lightBrightness / pow(dist, lightFalloffPower);
	lightVec = normalize(lightVec);
	
	// Derive normal data
	vec4 surfaceVec = texture2D(texture, vertTexCoord.xy);
	// Remap from 0,1 to -1,1
	surfaceVec = (surfaceVec * normalScalar) + normalAdder;
	
	// Derive diffuse lighting
	float dotValue = max( dot( lightVec, surfaceVec.xyz ),  0.0 );
	dotValue *= intensity;
	
	// Compute reflection vectors
	vec3 reflectionVec = reflect(-lightVec, surfaceVec);
	float eyeDot = max( dot(reflectionVec, eyeVec),  0.0);	// Clamped to avoid negatives
	
	// Compute specular power
	float specular = pow(eyeDot, lightSpecularPower) * intensity;
	
	// Composit color
	float value = dotValue + specular * lightSpecularBlend;
	vec4 color = vec4(value, value, value, surfaceVec.a);
	
	// Add light colour
	color *= lightColor;
	
	priorColor += color;
	
	gl_FragColor = priorColor;
}