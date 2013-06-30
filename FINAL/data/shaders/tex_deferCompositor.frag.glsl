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
// Input 5: foreground elements (such as HUD)
uniform sampler2D foregroundMap;
// Input 6: viewscreen warp
uniform sampler2D screenWarpMap;


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
  if(light < 0.5)
  {
    return( 2.0 * base * light );
  }
  else
  {
    return( 1.0 - 2.0 * (1.0 - light) * (1.0 - base) );
  }
}


vec4 texture2DChromaticAberration(sampler2D src, vec2 coordR, vec2 coordG, vec2 coordB)
{
	vec4 colR = texture2D(src, coordR);
	vec4 colG = texture2D(src, coordG);
	vec4 colB = texture2D(src, coordB);
	
	return(	vec4(colR.r, colG.g, colB.b, ( colR.a + colG.a + colB.a ) / 3.0 ) );
}


void main() {
	// Get screen distortion values
	vec4 screenWarpCol = texture2D(screenWarpMap, vertTexCoord.xy) * normalScalar + normalAdder;
	// Get space distortion values
	vec4 warpCol = (texture2D(warpMap, vertTexCoord.xy) * normalScalar + normalAdder) + screenWarpCol;
	
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
	
	// Create screen chromatic abberation coordinates
	vec2 cursorRs = vec2(vertTexCoord.xy + screenWarpCol.xy * chromAb.r * aspectRatioCorrection);
	vec2 cursorGs = vec2(vertTexCoord.xy + screenWarpCol.xy * chromAb.g * aspectRatioCorrection);
	vec2 cursorBs = vec2(vertTexCoord.xy + screenWarpCol.xy * chromAb.b * aspectRatioCorrection);
	
	vec4 bgCol = texture2DChromaticAberration(backgroundMap, cursorR, cursorG, cursorB);
	vec4 diffCol = texture2DChromaticAberration(texture, cursorR, cursorG, cursorB);
	vec4 lightCol = texture2DChromaticAberration(lightMap, cursorR, cursorG, cursorB);
	vec4 emitCol = texture2DChromaticAberration(emitMap, cursorR, cursorG, cursorB);
	// Foreground seeks without in-scene warp
	vec4 fgCol = texture2DChromaticAberration(foregroundMap, cursorRs, cursorGs, cursorBs);
	
	// Perform hard light operation
	vec4 litDiffCol = vec4(	hardLightChannel(diffCol.r, lightCol.r), 
							hardLightChannel(diffCol.g, lightCol.g), 
							hardLightChannel(diffCol.b, lightCol.b),
							diffCol.a );
	
	// Mix to background map
	vec4 litOnBGCol = mix(bgCol, litDiffCol, litDiffCol.a);
	// Add foreground
	//litOnBGCol = mix(litOnBGCol, fgCol, fgCol.a);
	litOnBGCol += fgCol;
	
	gl_FragColor = litOnBGCol + emitCol;
}