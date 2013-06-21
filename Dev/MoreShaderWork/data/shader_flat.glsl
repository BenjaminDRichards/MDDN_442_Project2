#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_COLOR_SHADER

void main(void)
{
  gl_FragColor = vec4(1.0, 0.5, 1.0, 1.0);
}