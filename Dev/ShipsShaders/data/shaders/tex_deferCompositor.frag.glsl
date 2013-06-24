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


// Input 1: light map
uniform sampler2D lightMap;
// Input 2: emission map
uniform sampler2D emitMap;
// Input 3: warp map
uniform sampler2D warpMap;
uniform vec2 aspectRatioCorrection;
// Input 4: pre-rendered background map
uniform sampler2D backgroundMap;


// Chromatic abberation parameters
// This is not 100% physically accurate,
//   but red light is genuinely affected more than blue.
const vec3 chromAb = vec3(0.1, 0.09, 0.08);


// Normal remap scalar
const vec4 normalScalar = vec4(2.0, 2.0, 2.0, 1.0);
// Normal remap addition
const vec4 normalAdder = vec4(-1.0, -1.0, -1.0, 0.0);


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


vec4 texture2DChromaticAberration(sampler2D src, vec2 coordR, vec2 coordG, vec2 coordB)
{
	return(	vec4(texture2D(src, coordR).r,
			texture2D(src, coordG).g, 
			texture2D(src, coordB).b, 
			( texture2D(src, coordR).a +
			texture2D(src, coordG).a + 
			texture2D(src, coordB).a ) / 3.0 )		);
}


void main() {
	// Get screen distortion values
	vec4 warpCol = texture2D(warpMap, vertTexCoord.xy) * normalScalar + normalAdder;
	
	/*
	// Create new texture coordinate
	vec2 cursor = vec2(vertTexCoord.xy + warpCol.xy * 0.1 * aspectRatioCorrection);
	vec4 bgCol = texture2D(backgroundMap, cursor);
	vec4 diffCol = texture2D(texture, cursor);
	vec4 lightCol = texture2D(lightMap, cursor);
	vec4 emitCol = texture2D(emitMap, cursor);
	*/
	
	// Create chromatic abberation coordinates
	vec2 cursorR = vec2(vertTexCoord.xy + warpCol.xy * chromAb.r * aspectRatioCorrection);
	vec2 cursorG = vec2(vertTexCoord.xy + warpCol.xy * chromAb.g * aspectRatioCorrection);
	vec2 cursorB = vec2(vertTexCoord.xy + warpCol.xy * chromAb.b * aspectRatioCorrection);
	
	vec4 bgCol = texture2DChromaticAberration(backgroundMap, cursorR, cursorG, cursorB);
	vec4 diffCol = texture2DChromaticAberration(texture, cursorR, cursorG, cursorB);
	vec4 lightCol = texture2DChromaticAberration(lightMap, cursorR, cursorG, cursorB);
	vec4 emitCol = texture2DChromaticAberration(emitMap, cursorR, cursorG, cursorB);
	
	// Perform hard light operation
	vec4 litDiffCol = vec4(	hardLightChannel(diffCol.r, lightCol.r), 
							hardLightChannel(diffCol.g, lightCol.g), 
							hardLightChannel(diffCol.b, lightCol.b),
							diffCol.a );
	
	// Mix to background map
	vec4 litOnBGCol = mix(bgCol, litDiffCol, litDiffCol.a);
	
	gl_FragColor = litOnBGCol + emitCol;
}