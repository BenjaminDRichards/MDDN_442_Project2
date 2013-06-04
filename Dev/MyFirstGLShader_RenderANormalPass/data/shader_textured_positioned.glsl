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
uniform vec2 poi;

void main(void)
{
  vec2 coord = gl_FragCoord.xy / resolution.xy;
  float dist = distance(coord, poi);
  float tempVal = 1.0 / (dist + 1.0);
  gl_FragColor = vec4(tempVal, tempVal, tempVal, 1.0);
}