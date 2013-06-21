#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
uniform sampler2D extraTexture;

uniform vec2 resolution;
uniform vec2 correcterMult;		// For coordinate inversions
uniform vec2 correcterAdd;		// For coordinate offsets
uniform mat3 customMatrix;

void main(void)
{
  // Adjust cursor to correct coord system
  vec2 cursor = gl_FragCoord.xy / resolution.xy;
  cursor = cursor * correcterMult + correcterAdd;
  
  // Transform cursor
  //float x = customMatrix[0][0] * cursor.x + customMatrix[0][1] * cursor.x + customMatrix[0][2] * cursor.x;
  //float y = customMatrix[1][0] * cursor.y + customMatrix[1][1] * cursor.y + customMatrix[1][2] * cursor.y;
  //cursor = vec2(x,y);
  float x = cursor.x * customMatrix[0][0];
  float y = cursor.y;
  cursor = vec2(x, y);
  
  // Do operation
  vec4 col = texture2D(texture, cursor);
  vec4 colExtra = texture2D(extraTexture, cursor);
  gl_FragColor = col + colExtra;
}