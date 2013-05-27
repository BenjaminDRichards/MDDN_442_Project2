#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;

uniform vec2 resolution;

void main(void)
{
  vec4 col = texture2D(texture, gl_FragCoord.xy / resolution.xy);
  gl_FragColor = col;
}