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
  
  OK, so those are PROCESSING_COLOR_SHADER shaders.
  Let's try for something more sophisticated:
  a texture type.
  
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
  
  Important result: the output texture is Y-inverted,
  and drawn from (0,0) even if the image is offset.
  So bits get cut off.
  The scale stays constant at native resolution.
  And the image is aligned to the bottom of the screen, not the top.
  The "resolution" parameter does define the scale of the image.
  
  Drawing to a buffer solves a number of issues.
  For example, shaders are _done_ when their draw is completed.
  The image can be slung around at will without issue.
  
  Another test shader, this time to determine crude distances:
  
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
  
  With this, we should be able to draw layers of normal-mapped light onto a buffer:
*/


PShader shader_flat, shader_flat_input, shader_textured, shader_textured_positioned, shader_textured_crudeNormal;
PGraphics sprite_buffer, sprite_buffer2;
PImage tex_diff, tex_norm;


void setup()
{
  size(800,600, P2D);
  noStroke();
  
  // Setup shader
  shader_flat = loadShader("shader_flat.glsl");
  shader_flat_input = loadShader("shader_flat_input.glsl");
  shader_textured = loadShader("shader_textured.glsl");
  shader_textured_positioned = loadShader("shader_textured_positioned.glsl");
  shader_textured_crudeNormal = loadShader("shader_textured_crudeNormal.glsl");
  
  // Setup draw buffers
  sprite_buffer = createGraphics(256, 256, P2D);
  sprite_buffer2 = createGraphics(512, 512, P2D);
  
  // Load and register textures
  tex_diff = loadImage("ship2_series7_diff_512.png");
  tex_norm = loadImage("ship2_series7_norm_512.png");
  //tex_norm = loadImage("norm2.png");
}


void draw()
{
  background(127);
  
  // Test flat colour shader
  /*
  shader(shader_flat);
  rect(0, 0,  width/2, height/2);
  resetShader();
  */
  
  // Test changing colour shader
  /*
  shader_flat_input.set("in_x", mouseX / (float) width);
  shader_flat_input.set("in_y", mouseY / (float) height);
  shader(shader_flat_input);
  rect(width/2, height/2,  width/2, height/2);
  resetShader();
  */
  
  // Test texture shader on main screen
  image(tex_diff,  0, 0);
  shader(shader_textured);
  image(tex_diff,  0, 0,  width * 0.5, width * 0.5);
  resetShader();
  
  // Test texture shader in custom buffer
  shader_textured.set("resolution", (float)sprite_buffer.width, (float)sprite_buffer.height);
  sprite_buffer.beginDraw();
  sprite_buffer.clear();
  sprite_buffer.shader(shader_textured);
  sprite_buffer.image(tex_diff,  0, 0,  sprite_buffer.width, sprite_buffer.height);
  sprite_buffer.endDraw();
  pushMatrix();
  translate(width * 0.5, 0);
  rotate( 0.1 * sin(frameCount * 0.05) + 0.1 );
  image(sprite_buffer, 0, 0);
  popMatrix();
  
  // Test distance shader
  /*
  shader_textured_positioned.set("resolution", (float)sprite_buffer2.width, (float)sprite_buffer2.height);
  shader_textured_positioned.set("poi", mouseX / (float)sprite_buffer2.width, 1.0 - mouseY / (float)sprite_buffer2.height);
  sprite_buffer2.beginDraw();
  sprite_buffer2.clear();
  sprite_buffer2.shader(shader_textured_positioned);
  sprite_buffer2.image(tex_diff,  0, 0,  sprite_buffer2.width, sprite_buffer2.height);
  sprite_buffer2.endDraw();
  pushMatrix();
  translate(0, height / 2.0);
  image(sprite_buffer2, 0,0);
  popMatrix();
  */
  
  // Test crude normal shader
  shader_textured_crudeNormal.set("resolution", (float)sprite_buffer2.width, (float)sprite_buffer2.height);
  shader_textured_crudeNormal.set("poi", mouseX / (float)sprite_buffer2.width,
                                         1.0 - mouseY / (float)sprite_buffer2.height,
                                         1.0);
  shader_textured_crudeNormal.set("specPower", 4.0);
  shader_textured_crudeNormal.set("light_falloff", 2.0);
  shader_textured_crudeNormal.set("light_brightness", 1.0);
  
  sprite_buffer2.beginDraw();
  sprite_buffer2.clear();
  sprite_buffer2.shader(shader_textured_crudeNormal);
  int TEST_COUNT = 8;
  for(int i = 0;  i < TEST_COUNT;  i++)
  {
    sprite_buffer2.image(tex_norm,  0, 0,  sprite_buffer2.width, sprite_buffer2.height);
  }
  sprite_buffer2.resetShader();
  sprite_buffer2.endDraw();
  
  image(sprite_buffer2, 0,0);
  
  
  
  // Diagnostic
  //println("FPS " + frameRate);
}
