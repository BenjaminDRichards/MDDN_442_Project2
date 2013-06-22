/*

*/


import java.util.*;


PImage tex_diff, tex_norm;
RenderManager renderManager;
ArrayList testSprites;

PImage lightStencil;


void setup()
{
  size(1280, 720, P2D);
  //frameRate(30);
  noStroke();
  
  renderManager = new RenderManager(g);
  
  // Load and register textures
  tex_diff = loadImage("ship2_series7_diff_512.png");
  tex_norm = loadImage("ship2_series7_norm_512.png");
  lightStencil = loadImage("lightStencil.png");
  
  
  // Test sprite systems
  
  // Initiate temporary assets
  PGraphics weiss = createGraphics(tex_diff.width, tex_diff.height, P2D);
  weiss.beginDraw();
  weiss.clear();
  weiss.image(tex_diff, 0,0);
  weiss.loadPixels();
  for(int i = 0;  i < weiss.pixels.length;  i++)
  {
    color col = weiss.pixels[i];
    weiss.pixels[i] = color( 255, alpha(col) );
  }
  weiss.updatePixels();
  weiss.endDraw();
  
  PGraphics schwartz = createGraphics(tex_diff.width, tex_diff.height, P2D);
  schwartz.beginDraw();
  schwartz.clear();
  schwartz.image(tex_diff, 0,0);
  schwartz.loadPixels();
  for(int i = 0;  i < schwartz.pixels.length;  i++)
  {
    color col = schwartz.pixels[i];
    schwartz.pixels[i] = color( 0, alpha(col) );
  }
  schwartz.updatePixels();
  schwartz.endDraw();
  
  // Initiate sprites
  testSprites = new ArrayList();
  for(int i = 0;  i < 64;  i++)
  {
    DAGTransform dag = new DAGTransform(random(width), random(height), 0,  random(TWO_PI),  1,1,1);
    Sprite s = new Sprite(dag, tex_diff, 512, 512, -0.5, -0.5);
    s.setSpecular(weiss);
    s.setEmissive(schwartz);
    s.setNormal(tex_norm);
    testSprites.add(s);
  }
}


void draw()
{
  background(64);
  
  // Render manager test
  
  // Generate lights
  int lightPop = 256;
  for(int i = 0;  i < lightPop;  i++)
  {
    // Position stencil
    float lightPosOffsetAng = TWO_PI * 3 * sqrt(i / (float) lightPop);
    PVector lightPosOffset = new PVector( cos(lightPosOffsetAng), sin(lightPosOffsetAng) );
    lightPosOffset.mult( (512/(float)lightPop) * i);
    PVector lpo = lightPosOffset;
    PVector lightPos = new PVector(mouseX + lpo.x, mouseY + lpo.y);
    
    color lcol = color(255 * abs(sin(i)), 255 * abs(sin(i * 0.7)), 255 * abs(sin(i * -3.1)), 255 * 1.0);
    Light light = new Light(lightPos, 0.01, lcol);
    
    renderManager.addLight(light);
  }
  
  // Prep sprite
  Iterator i = testSprites.iterator();
  while( i.hasNext() )
  {
    Sprite s = (Sprite) i.next();
    s.transform.rotate(0.01);
    renderManager.addSprite(s);
  }
  // Complete render management
  renderManager.render();
  
  
  
  /*
  // Save to file
  save("render/render" + nf(frameCount, 5) + ".png");
  if(1800 < frameCount)  exit();
  */
  
  
  // Diagnostic
  if(frameCount % 60 == 0)  println("FPS " + frameRate);
}





color packFloatToColor(float in)
// Packs a float in the range -127,127 into a color for use in shaders
{
  return( color( floor(in) + 127, floor(in * 255.0), floor(in * 255.0 * 255.0), 255 ) );
}
// packFloatToColor


void splitToBuffers(PVector vec, PGraphics b1, PGraphics b2, PGraphics b3, int index)
// Packs a vector into three buffers as packed color-floats
// Buffers must be drawable
{
  b1.pixels[index] = packFloatToColor(vec.x);
  b2.pixels[index] = packFloatToColor(vec.y);
  b3.pixels[index] = packFloatToColor(vec.z);
}
// splitToBuffers


PVector vectorToTextureNormal(PVector vec)
// Turns any vector into a normalised vector in the range 0-1
{
  PVector v = vec.get();
  v.normalize();
  v = new PVector(v.x * 0.5 + 0.5, v.y * 0.5 + 0.5, v.z * 0.5 + 0.5);
  v.mult(255.0);
  return( v );
}
// vectorToTextureNormal
