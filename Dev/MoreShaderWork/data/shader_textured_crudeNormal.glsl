#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

// Used by Processing, I think
uniform sampler2D texture;
// Normalise texture coordinates
uniform vec2 resolution;
// Pre-normalised point-of-interest coordinates
uniform vec3 poi;
// Specular power
uniform float specPower;
// Light parameters
uniform float light_falloff;
uniform float light_brightness;

// Normal remap scalar
const vec4 normalScalar = vec4(2.0, -2.0, 2.0, 1.0);	// Note Y-axis correction
// Normal remap addition
const vec4 normalAdder = vec4(-1.0, 1.0, -1.0, 0.0);	// Note Y-axis correction
// Eye vector is always perpendicular to view plane
const vec3 eyeVec = vec3(0.0, 0.0, 1.0);

void main(void)
{
  // Derive normal data
  vec4 normalMapValue = texture2D(texture, gl_FragCoord.xy / resolution.xy);
  // Remap
  normalMapValue = normalMapValue * normalScalar + normalAdder;
  
  // Compute flat surface vectors
  vec2 coord = gl_FragCoord.xy / resolution.xy;
  vec3 lightVec = poi.xyz - vec3(coord.x, coord.y, 0);
  float dist = length(lightVec);
  lightVec = normalize(lightVec);
  //vec3 surfaceVec = vec3(0.0, 0.0, 1.0);  // Default, even surface
  vec3 surfaceVec = normalMapValue.xyz;
  float dotValue = max( dot( lightVec, surfaceVec ),  0.0 );
  
  // Compute diffuse illumination of surface
  float lightIntensity = light_brightness / pow(dist, light_falloff);
  float diffuse = dotValue * lightIntensity;
  
  // Compute reflection vectors
  vec3 reflectionVec = reflect(-lightVec, normalMapValue);
  float eyeDot = max( dot(reflectionVec, eyeVec),  0.0);	// Clamped to avoid negatives
  
  // Compute specular power
  float specular = pow(eyeDot, specPower) * light_brightness;
  
  // Compute final colour
  //float finalColor = diffuse;
  //float finalColor = specular;
  float finalColor = diffuse + specular;
  
  gl_FragColor = vec4(finalColor, finalColor, finalColor, normalMapValue.w);
}
