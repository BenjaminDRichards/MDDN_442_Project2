/*
Note to self:

hey

    HEY

you should REMEMBER THIS

Trying to do a one-step shader next. No deferred normal caching. 
Just recompute the relative light positions for every sprite.
Might have superior performance.
Can also procure only the strongest lights for acceleration.

This approach removes the need to pre-rotate and cache normal maps.
It requires all the maps to be fed into the one shader: diffuse, specular, emit, and normal.
Presumably we'd use diffuse as the base.
*/


import java.util.*;

PShader tex, tex_normDeferrer, tex_deferLighting, tex_deferLightingImgdata, tex_deferCompositor;
PImage tex_diff, tex_norm;

PGraphics deferDiff, deferNorm, deferSpec, deferLight, deferEmit;

PVector bufferRes;
PGraphics bufferLightPos, bufferLightCol, bufferLightBrt;
PGraphics lightPosBufferX, lightPosBufferY, lightPosBufferZ;


void setup()
{
  size(1920, 1080, P2D);
  //frameRate(30);
  noStroke();
  
  // Setup shader
  tex = loadShader("tex.frag.glsl", "tex.vert.glsl");
  tex_normDeferrer = loadShader("tex_normDeferrer.frag.glsl", "tex.vert.glsl");
  tex_deferLighting = loadShader("tex_deferLighting.frag.glsl", "tex.vert.glsl");
  tex_deferLightingImgdata = loadShader("tex_deferLightingImgdata.frag.glsl", "tex.vert.glsl");
  tex_deferCompositor = loadShader("tex_deferCompositor.frag.glsl", "tex.vert.glsl");
  
  // Setup draw buffers
  deferDiff = createGraphics(width, height, P2D);
  deferDiff.beginDraw();  deferDiff.clear();  deferDiff.endDraw();
  deferNorm = createGraphics(width, height, P2D);
  deferNorm.beginDraw();  deferNorm.clear();  deferNorm.endDraw();
  deferSpec = createGraphics(width, height, P2D);
  deferSpec.beginDraw();  deferSpec.background(255);  deferSpec.endDraw();
  deferLight = createGraphics(width, height, P2D);
  deferLight.beginDraw();  deferLight.clear();  deferLight.endDraw();
  deferEmit = createGraphics(width, height, P2D);
  deferEmit.beginDraw();  deferEmit.clear();  deferEmit.endDraw();
  
  
  // Image based buffer test
  bufferRes = new PVector(4.0, 4.0);  // 64 is about the limit, it seems - 16 is even safer
  
  // Buffer random lights into an image
  bufferLightPos = createGraphics((int)bufferRes.x, (int)bufferRes.y, JAVA2D);
  bufferLightPos.beginDraw();
  bufferLightPos.loadPixels();
  for(int i = 0;  i < bufferLightPos.pixels.length;  i++)
  {
    bufferLightPos.pixels[i] = color(random(255), random(255), 8, 255);
  }
  bufferLightPos.updatePixels();
  bufferLightPos.endDraw();
  
  // Buffer random light positions into three float-capable buffers
  lightPosBufferX = createGraphics( (int)bufferRes.x, (int)bufferRes.y, JAVA2D );
  lightPosBufferY = createGraphics( (int)bufferRes.x, (int)bufferRes.y, JAVA2D );
  lightPosBufferZ = createGraphics( (int)bufferRes.x, (int)bufferRes.y, JAVA2D );
  lightPosBufferX.beginDraw();  lightPosBufferX.loadPixels();
  lightPosBufferY.beginDraw();  lightPosBufferY.loadPixels();
  lightPosBufferZ.beginDraw();  lightPosBufferZ.loadPixels();
  for(int i = 0;  i < lightPosBufferX.pixels.length;  i++)
  {
    PVector pos = PVector.random3D();
    splitToBuffers(pos, lightPosBufferX, lightPosBufferY, lightPosBufferZ, i);
  }
  lightPosBufferX.updatePixels();  lightPosBufferX.endDraw();
  lightPosBufferY.updatePixels();  lightPosBufferY.endDraw();
  lightPosBufferZ.updatePixels();  lightPosBufferZ.endDraw();
  
  // Buffer random light colours into an image
  bufferLightCol = createGraphics((int)bufferRes.x, (int)bufferRes.y, JAVA2D);
  bufferLightCol.beginDraw();
  bufferLightCol.loadPixels();
  for(int i = 0;  i < bufferLightCol.pixels.length;  i++)
  {
    bufferLightCol.pixels[i] = color(random(255), random(255), random(255), 255);
  }
  bufferLightCol.updatePixels();
  bufferLightCol.endDraw();
  
  // Buffer light brightnesses into an image
  bufferLightBrt = createGraphics((int)bufferRes.x, (int)bufferRes.y, JAVA2D);
  bufferLightBrt.beginDraw();
  bufferLightBrt.loadPixels();
  for(int i = 0;  i < bufferLightBrt.pixels.length;  i++)
  {
    float brt = random(1.0) / (bufferRes.x * bufferRes.y);
    bufferLightBrt.pixels[i] = packFloatToColor(brt);
  }
  bufferLightBrt.updatePixels();
  bufferLightBrt.endDraw();
  
  // Load and register textures
  tex_diff = loadImage("ship2_series7_diff_512.png");
  tex_norm = loadImage("ship2_series7_norm_512.png");
}


void draw()
{
  background(127);
  
  
  // Test complicated stuff
  
  // Define transforms and data
  PImage imgD = tex_diff;
  PImage imgN = tex_norm;
  PVector pos1 = new PVector(256,256);  //(mouseX, mouseY);
  float ang = frameCount * 0.005;
  PVector pos2 = new PVector(-imgD.width * 0.5, -imgD.height * 0.5);
  PVector posLight = new PVector(mouseX/(float)width, 1.0 - mouseY/(float)height, 0.25);
  
  // Draw to diffuse buffer
  deferDiff.beginDraw();  deferDiff.clear();
  deferDiff.image(imgD, 0,0);
  deferDiff.translate(pos1.x, pos1.y);  deferDiff.rotate(ang);  deferDiff.translate(pos2.x, pos2.y);
  deferDiff.image(imgD, 0,0);
  deferDiff.endDraw();
  
  // Draw to normal buffer
  deferNorm.beginDraw();  deferNorm.noSmooth();  deferNorm.clear();
    deferNorm.image(imgN, 0,0);
  deferNorm.translate(pos1.x, pos1.y);  deferNorm.rotate(ang);  deferNorm.translate(pos2.x, pos2.y);
  deferNorm.shader(tex_normDeferrer);
  tex_normDeferrer.set("worldAngle", ang);
  deferNorm.image(imgN, 0,0);
  deferNorm.resetShader();
  deferNorm.endDraw();
  
  
  // Composit final light buffer
  
  //Update light buffer
  lightPosBufferX.beginDraw();  lightPosBufferX.loadPixels();
  lightPosBufferY.beginDraw();  lightPosBufferY.loadPixels();
  lightPosBufferZ.beginDraw();  lightPosBufferZ.loadPixels();
  splitToBuffers(posLight, lightPosBufferX, lightPosBufferY, lightPosBufferZ, 0);
  lightPosBufferX.updatePixels();  lightPosBufferX.endDraw();
  lightPosBufferY.updatePixels();  lightPosBufferY.endDraw();
  lightPosBufferZ.updatePixels();  lightPosBufferZ.endDraw();
  bufferLightBrt.beginDraw();  bufferLightBrt.loadPixels();
  bufferLightBrt.pixels[0] = packFloatToColor(0.1);
  bufferLightBrt.updatePixels();  bufferLightBrt.endDraw();
  
  
  deferLight.beginDraw();  deferLight.clear();
  
  deferLight.shader(tex_deferLightingImgdata);
  tex_deferLightingImgdata.set("srcAspectRatio", (float)deferLight.height / (float)deferLight.width);
  tex_deferLightingImgdata.set("lightFalloffPower", 2.0);
  tex_deferLightingImgdata.set("lightSpecularPower", 4.0);
  tex_deferLightingImgdata.set("lightSpecularBlend", deferSpec);
  tex_deferLightingImgdata.set("lightBufferDimensions", (float)bufferLightPos.width, (float)bufferLightPos.height);
  tex_deferLightingImgdata.set("lightPosBufferX", lightPosBufferX);
  tex_deferLightingImgdata.set("lightPosBufferY", lightPosBufferY);
  tex_deferLightingImgdata.set("lightPosBufferZ", lightPosBufferZ);
  tex_deferLightingImgdata.set("lightColBuffer", bufferLightCol);
  tex_deferLightingImgdata.set("lightBrtBuffer", bufferLightBrt);
  
  deferLight.image(deferNorm, 0,0);
  
  deferLight.endDraw();
  
  // Diagnose input buffers
  pushMatrix();
  image(bufferLightPos, 0,0, 64, 64);
  translate(0, 64);
  image(bufferLightCol, 0,0, 64, 64);
  translate(0, 64);
  image(bufferLightBrt, 0,0, 64, 64);
  popMatrix();
  
  // Draw to specular buffer
  
  // Draw to emit buffer
  
  // Bloom emit buffer
  
  // Fold down buffers
  shader(tex_deferCompositor);
  tex_deferCompositor.set("lightMap", deferLight);
  tex_deferCompositor.set("emitMap", deferEmit);
  image(deferDiff, 0,0);
  resetShader();
  
  
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
