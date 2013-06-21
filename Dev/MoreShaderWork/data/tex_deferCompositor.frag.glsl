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


// Input 1: light maps
uniform sampler2D lightMap;
// Input 2: emission maps
uniform sampler2D emitMap;


float hardLightChannel(float base, float light)
{
  float value = 0;
  if(light < 0.5)
  {
    value = 2.0 * base * light;
  }
  else
  {
    value = 1.0 - 2.0 * (1.0 - light) * (1.0 - base);
  }
  return( value );
}


void main() {
  vec4 diffCol = texture2D(texture, vertTexCoord.xy);
  vec4 lightCol = texture2D(lightMap, vertTexCoord.xy);
  vec4 emitCol = texture2D(emitMap, vertTexCoord.xy);
  
  // Perform hard light operation
  vec4 litDiffCol = vec4(	hardLightChannel(diffCol.r, lightCol.r), 
							hardLightChannel(diffCol.g, lightCol.g), 
							hardLightChannel(diffCol.b, lightCol.b),
							diffCol.a );
  
  gl_FragColor = litDiffCol + emitCol;
}