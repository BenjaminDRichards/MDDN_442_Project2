/*

*/


import java.util.*;

PGL pgl;

PShader tex, tex_normDeferrer, tex_deferLighting, tex_deferLightingImgdata, tex_deferCompositor;
PShader tex_lightByImage;
PGraphics lightByImageStencil;
PImage tex_diff, tex_norm;

PGraphics deferDiff, deferNorm, deferSpec, deferLight, deferEmit;


void setup()
{
  size(1280, 720, P2D);
  //frameRate(30);
  noStroke();
  
  // Setup shader
  tex = loadShader("tex.frag.glsl", "tex.vert.glsl");
  tex_normDeferrer = loadShader("tex_normDeferrer.frag.glsl", "tex.vert.glsl");
  tex_deferLighting = loadShader("tex_deferLighting.frag.glsl", "tex.vert.glsl");
  tex_deferLightingImgdata = loadShader("tex_deferLightingImgdata.frag.glsl", "tex.vert.glsl");
  tex_deferCompositor = loadShader("tex_deferCompositor.frag.glsl", "tex.vert.glsl");
  tex_lightByImage = loadShader("tex_lightByImage.frag.glsl", "tex.vert.glsl");
  
  // Setup draw buffers
  PVector highRes = new PVector( width, height );
  PVector lowRes = new PVector( highRes.x / 2.0, highRes.y / 2.0 );
  deferDiff = createGraphics( int(highRes.x), int(highRes.y), P2D);
  deferDiff.beginDraw();  deferDiff.clear();  deferDiff.endDraw();
  deferNorm = createGraphics( int(highRes.x), int(highRes.y), P2D);
  deferNorm.beginDraw();  deferNorm.noSmooth();  deferNorm.clear();  deferNorm.endDraw();
  deferSpec = createGraphics( int(highRes.x), int(highRes.y), P2D);
  deferSpec.beginDraw();  deferSpec.background(255);  deferSpec.endDraw();
  deferLight = createGraphics( int(highRes.x), int(highRes.y), P2D );
  //deferLight = createGraphics( int(lowRes.x), int(lowRes.y), P2D );
  deferLight.beginDraw();  deferLight.clear();  deferLight.endDraw();
  deferEmit = createGraphics( int(highRes.x), int(highRes.y), P2D);
  deferEmit.beginDraw();  deferEmit.clear();  deferEmit.endDraw();
  
  
  // Light stencil
  lightByImageStencil = createGraphics(256,256, JAVA2D);
  PGraphics lbis = lightByImageStencil;
  lbis.beginDraw();
  lbis.clear();
  PVector lightCentre = new PVector(lbis.width / 2.0, lbis.height / 2.0, lbis.height / 2.0);
  for(int y = 0;  y < lbis.height;  y++)
  for(int x = 0;  x < lbis.width;  x++)
  {
    PVector surfaceVec = new PVector(x, y, 0);
    PVector lightVec = PVector.sub(lightCentre, surfaceVec);
    PVector normCol = vectorToTextureNormal(lightVec);
    float aleph = 255.0 * lightCentre.z / lightVec.mag();  // Intensity based on distance
    // Scale down to 0 at the edges
    float alephMod = 1.0 - ( surfaceVec.dist( new PVector(lightCentre.x, lightCentre.y, 0) ) / (lbis.width * 0.5) );
    aleph *= alephMod;
    lbis.set( x, y, color(normCol.x, normCol.y, normCol.z, aleph) );
  }
  lbis.endDraw();
  
  // Load and register textures
  tex_diff = loadImage("ship2_series7_diff_512.png");
  tex_norm = loadImage("ship2_series7_norm_512.png");
}


void draw()
{
  background(64);
  
  
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
  deferDiff.translate(pos1.x, pos1.y);
  for(int i = 0;  i < 8;  i++)
  {
    deferDiff.pushMatrix();
    deferDiff.translate(i * 128, i * 64);
    deferDiff.rotate(ang / (float)i);
    deferDiff.translate(pos2.x, pos2.y);
    deferDiff.image(imgD, 0,0);
    deferDiff.popMatrix();
  }
  deferDiff.endDraw();
  
  // Draw to normal buffer
  deferNorm.beginDraw();  deferNorm.clear();
  deferNorm.shader(tex_normDeferrer);
  deferNorm.translate(pos1.x, pos1.y);
  for(int i = 0;  i < 8;  i++)
  {
    deferNorm.pushMatrix();
    deferNorm.translate(i * 128, i * 64);
    float newAng = ang / (float)i;
    deferNorm.rotate(newAng);
    tex_normDeferrer.set("worldAngle", newAng);
    deferNorm.translate(pos2.x, pos2.y);
    deferNorm.image(imgN, 0,0);
    deferNorm.popMatrix();
  }
  deferNorm.resetShader();
  deferNorm.endDraw();
  
  
  // Composit final light buffer
  
  // Draw to specular buffer
  
  // Draw to emit buffer
  
  // Bloom emit buffer
  
  // Fold down buffers
  shader(tex_deferCompositor);
  tex_deferCompositor.set("lightMap", deferLight);
  tex_deferCompositor.set("emitMap", deferEmit);
  //image(deferDiff, 0,0, width,height);
  resetShader();
  
  
  // Test light stenciling
  
  // Underlay
  image(deferDiff, 0,0, width,height);
  
  // Clear buffer
  deferLight.beginDraw();  deferLight.background(0);  deferLight.endDraw();
  
  // Set initial light parameters
  tex_lightByImage.set("lightSpecularPower", 4.0);
  tex_lightByImage.set("lightColor", 1.0, 0.5, 0.25, 1.0);
  tex_lightByImage.set("lightBrightness", 0.01);
  tex_lightByImage.set("normalMap", deferNorm);
  tex_lightByImage.set("lightSpecularMap", deferSpec);
  // This starts to drop below 60fps with 256 lights covering 256-pixel diameter areas
  // Pretty good so far...
  //
  // Further implementation requires begin/endDraw calls, dropping acceptable count to under 64.
  //
  // By allowing transparent outputs in the shader, we're able to begin/end just once.
  // This doesn't do a very good job of blending, just an alpha combination...
  // We really want the fragments to add, not blend.
  // But it pushes light population up near 256 again.
  //
  // The fragment blend function is actually accessible! Hooray!
  // It looks great and performs happily with 256 lights.
  deferLight.beginDraw();
  pgl = deferLight.beginPGL();
  pgl.blendFunc(PGL.ONE, PGL.ONE);
  int lightPop = 256;
  for(int i = 0;  i < lightPop;  i++)
  {
    // Position stencil
    float stencilPosOffsetAng = TWO_PI * 3 * sqrt(i / (float) lightPop);
    PVector stencilPosOffset = new PVector( cos(stencilPosOffsetAng), sin(stencilPosOffsetAng) );
    stencilPosOffset.mult( (512/(float)lightPop) * i);
    PVector spo = stencilPosOffset;
    PVector stencilPos = new PVector(mouseX + spo.x, mouseY + spo.y);
    float stencilDiameter = 256;
    PVector stencilCorner = new PVector(stencilPos.x - stencilDiameter / 2, stencilPos.y - stencilDiameter / 2);
    
    // Derive coordinates relative to submaps
    // Because OpenGL measures from the bottom of the screen, our Y values are a little unusual
    PVector mapScale = new PVector(stencilDiameter / (float)deferNorm.width,
                                   -stencilDiameter / (float)deferNorm.height);
    // The image is now correctly proportioned, but in negative space and must be corrected by (0, 1)
    // Y values are measured from the bottom of the screen now
    PVector mapOffset = new PVector( stencilCorner.x / (float)deferNorm.width,
        -stencilCorner.y / (float)deferNorm.height );
    // Correct negative position
    mapOffset.add( new PVector(0.0, 1.0) );
    // Set shader parameters
    tex_lightByImage.set("mapCoordScale", mapScale.x, mapScale.y);
    tex_lightByImage.set("mapCoordOffset", mapOffset.x, mapOffset.y);
    tex_lightByImage.set("lightColor", abs(sin(i)), abs(sin(i * 0.7)), abs(sin(i * -3.1)), 1.0 );
    
    // Draw light stencil
    //deferLight.beginDraw();
    deferLight.shader(tex_lightByImage); 
    deferLight.pushMatrix();
    deferLight.translate(stencilCorner.x, stencilCorner.y);
    deferLight.image(lightByImageStencil, 0, 0, stencilDiameter, stencilDiameter);
    deferLight.popMatrix();
    deferLight.resetShader();
    //deferLight.endDraw();
  }
  deferLight.endDraw();
  endPGL();
  
  //image(deferLight, 0,0);
  
  // Fold down buffers
  shader(tex_deferCompositor);
  tex_deferCompositor.set("lightMap", deferLight);
  tex_deferCompositor.set("emitMap", deferEmit);
  image(deferDiff, 0,0, width,height);
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
