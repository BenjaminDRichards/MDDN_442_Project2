/*
  In which Ben attempts to write a proper GL shader just by looking at examples...
  
  Let's try something ridiculously simple: make everything a flat colour.
  
  shader_flat.glsl:
    #ifdef GL_ES
    precision mediump float;
    precision mediump int;
    #endif
    
    #define PROCESSING_COLOR_SHADER
    
    void main(void)
    {
      gl_FragColor = vec4(1.0, 0.5, 1.0, 1.0);
    }
  
  That works. Now let's push the mouse position into it to change the colour balance.
  
  shader_flat_input.glsl:
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
*/


PShader shader_flat, shader_flat_input;


void setup()
{
  size(800,600, P2D);
  
  // Setup shader
  shader_flat = loadShader("shader_flat.glsl");
  shader_flat_input = loadShader("shader_flat_input.glsl");
}


void draw()
{
  background(0);
  
  shader(shader_flat);
  rect(0, 0,  width/2, height/2);
  resetShader();
  
  shader_flat_input.set("in_x", mouseX / (float) width);
  shader_flat_input.set("in_y", mouseY / (float) height);
  shader(shader_flat_input);
  rect(width/2, height/2,  width/2, height/2);
}
