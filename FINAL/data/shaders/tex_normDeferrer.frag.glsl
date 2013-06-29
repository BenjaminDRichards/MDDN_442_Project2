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


void main() {
  // Derive normal data
  vec4 normalMapValue = texture2D(texture, vertTexCoord.xy);
  
  // Remap from 0,1 to -1,1
  normalMapValue = (normalMapValue * normalScalar) + normalAdder;
  // Counter-rotate vector
  float x = normalMapValue.x;
  float y = normalMapValue.y;
  float derivedAngle = atan(x, y) + worldAngle;
  float d = length( vec2(x, y) );
  x = cos(derivedAngle) * d;
  y = sin(derivedAngle) * d;
  
  normalMapValue = vec4(x, y, normalMapValue.z, normalMapValue.a);
  
  // Remap back into 0,1
  normalMapValue = (normalMapValue - normalAdder) / normalScalar;
  
  gl_FragColor = normalMapValue * vertColor;
}