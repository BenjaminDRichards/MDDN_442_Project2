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


uniform float srcAspectRatio;			// Used to determine some scaling factors
// Light data
uniform float lightFalloffPower;
uniform float lightSpecularPower;
uniform sampler2D lightSpecularBlend;

uniform vec2 lightBufferDimensions;
uniform sampler2D lightPosBufferX;
uniform sampler2D lightPosBufferY;
uniform sampler2D lightPosBufferZ;
uniform sampler2D lightColBuffer;
uniform sampler2D lightBrtBuffer;

// Eye vector is always perpendicular to view plane
const vec3 eyeVec = vec3(0.0, 0.0, 1.0);
// Normal remap scalar
const vec4 normalScalar = vec4(2.0, 2.0, 2.0, 1.0);
// Normal remap addition
const vec4 normalAdder = vec4(-1.0, -1.0, -1.0, 0.0);


// Method for unpacking floats in range -127,127 from RGB data
float extractFloat(vec3 col)
{
	return( col.r * 255.0 - 127 + col.g + col.b / 255.0 );
}


void main()
{
	// Derive normal data
	// Remap from 0,1 to -1,1
	vec4 surfaceVec = (texture2D(texture, vertTexCoord.xy) * normalScalar) + normalAdder;
	
	if(0 < surfaceVec.a )
	{
		// Initiate colour buffer
		vec4 sumColor = vec4(0.0, 0.0, 0.0, 1.0);
		
		// Derive specular data
		float specularStrength = texture2D(lightSpecularBlend, vertTexCoord.xy).x;
		
		// Step through buffer elements
		for(int bufferX = 0;  bufferX < lightBufferDimensions.x;  bufferX++)
		{
			for(int bufferY = 0;  bufferY < lightBufferDimensions.y;  bufferY++)
			{
				// Derive data from buffers
				vec2 bufferCursor = vec2( bufferX / lightBufferDimensions.x, 
					bufferY / lightBufferDimensions.y);
				vec4 extractedCol = texture2D(lightColBuffer, bufferCursor);
				vec4 extractedBrt = texture2D(lightBrtBuffer, bufferCursor);
				// Depack compressed data
				float xLightBrightness = extractFloat(extractedBrt);
				
				// Derive buffered position
				// This has been packed into three buffers
				vec3 xLightPosition = vec3( extractFloat( texture2D(lightPosBufferX, bufferCursor) ),
											extractFloat( texture2D(lightPosBufferY, bufferCursor) ),
											extractFloat( texture2D(lightPosBufferZ, bufferCursor) ) );
				
				// Derive light vector
				vec3 lightVec = xLightPosition - vec3(vertTexCoord.xy, 0.0);
				
				// Derive light distance information
				// Correct for non-square draw regions
				lightVec *= vec3(1.0, srcAspectRatio, 1.0);
				float dist = length(lightVec);
				float lightIntensity = xLightBrightness / pow(dist, 1.0 / lightFalloffPower);
				lightVec = normalize(lightVec);
				
				// Derive diffuse lighting
				float diffValue = max( dot( lightVec, surfaceVec.xyz ),  0.0 );
				diffValue *= lightIntensity;
				
				// Compute reflection vectors
				vec3 reflectionVec = reflect(-lightVec, surfaceVec);
				float eyeDot = max( dot(reflectionVec, eyeVec),  0.0);	// Clamped to avoid negatives
				
				// Compute specular power
				float specular = pow(eyeDot, lightSpecularPower) * lightIntensity;
				
				// Composit color
				float value = diffValue + specular * specularStrength;
				sumColor += vec4(value, value, value, surfaceVec.a) * vec4(extractedCol.rgb, 1.0);
				
				// Light indicator
				//vec2 lightFlat = xLightPosition.xy;
				//vec2 screenVec = lightFlat - vertTexCoord;
				//float screenDist = length(screenVec);
				//if(screenDist < 0.01)
				//{
				//	sumColor = vec4(extractedCol.xyz, 1.0);
				//}
			}
		}
		
		gl_FragColor = sumColor;
	}
}