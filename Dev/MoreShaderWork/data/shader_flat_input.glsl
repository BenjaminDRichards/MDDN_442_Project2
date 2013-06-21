#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_COLOR_SHADER

uniform float in_x;
uniform float in_y;

void main(void)
{
  gl_FragColor = vec4(in_x, in_y, 0.0, 1.0);
}