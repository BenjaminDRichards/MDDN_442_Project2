import java.util.*;

PShader shader_flat, shader_flat_input, shader_textured, shader_textured_positioned, shader_textured_crudeNormal,
  shader_textured_twoTextures, shader_textured_normal_transform,
  tex, tex_normDeferrer, tex_deferLighting, tex_deferLightingImgdata, tex_deferCompositor;
PGraphics sprite_buffer, sprite_buffer2;
PImage tex_diff, tex_norm;
PGraphics tex_diff_pg, tex_norm_pg;

PGraphics deferDiff, deferNorm, deferSpec, deferLight, deferEmit;

ArrayList lights, lightCols;
PVector bufferRes;
PGraphics bufferLightPos, bufferLightCol, bufferLightBrt;
PGraphics lightPosBufferX, lightPosBufferY, lightPosBufferZ;


void setup()
{
  size(1920, 1080, P2D);
  //frameRate(30);
  noStroke();
  
  // Setup shader
  shader_flat = loadShader("shader_flat.glsl");
  shader_flat_input = loadShader("shader_flat_input.glsl");
  shader_textured = loadShader("shader_textured.glsl");
  shader_textured_positioned = loadShader("shader_textured_positioned.glsl");
  shader_textured_crudeNormal = loadShader("shader_textured_crudeNormal.glsl");
  shader_textured_twoTextures = loadShader("shader_textured_twoTextures.glsl");
  shader_textured_normal_transform = loadShader("shader_textured_normal_transform.glsl");
  tex = loadShader("tex.frag.glsl", "tex.vert.glsl");
  tex_normDeferrer = loadShader("tex_normDeferrer.frag.glsl", "tex.vert.glsl");
  tex_deferLighting = loadShader("tex_deferLighting.frag.glsl", "tex.vert.glsl");
  tex_deferLightingImgdata = loadShader("tex_deferLightingImgdata.frag.glsl", "tex.vert.glsl");
  tex_deferCompositor = loadShader("tex_deferCompositor.frag.glsl", "tex.vert.glsl");
  
  // Setup draw buffers
  sprite_buffer = createGraphics(256, 256, P2D);
  sprite_buffer2 = createGraphics(512, 512, P2D);
  
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
  
  /*
  // Make a whole lotta lights
  int lightCount = 64;
  lights = new ArrayList();
  lightCols = new ArrayList();
  for(int i = 0;  i < lightCount;  i++)
  {
    PVector lpos = new PVector( random(1.0), random(1.0), 1.0 );
    lights.add(lpos);
    PVector lcol = new PVector( random(255), random(255), random(255) );
    lightCols.add(lcol);
  }
  */
  
  // Image based buffer test
  bufferRes = new PVector(4.0, 4.0);  // 64 is about the limit, it seems - 16 is even safer
  
  // Buffer random lights into an image
  bufferLightPos = createGraphics((int)bufferRes.x, (int)bufferRes.y, JAVA2D);
  bufferLightPos.beginDraw();
  bufferLightPos.loadPixels();
  for(int i = 0;  i < bufferLightPos.pixels.length;  i++)
  {
    bufferLightPos.pixels[i] = color(random(255), random(255), 8, 255);
    /*
    float xpos = (i % bufferLightPos.width) * 255.0 / (float)bufferLightPos.width;
    float ypos = floor( i / bufferLightPos.width ) * 255.0 / (float)bufferLightPos.height;
    bufferLightPos.pixels[i] = color(xpos, ypos, 255, 255);
    */
    //bufferLightPos.pixels[i] = color(255 * i / (float) bufferLightPos.pixels.length,  127,  255, 255);
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
  //tex_norm = loadImage("norm2.png");
  
  tex_diff_pg = createGraphics(tex_diff.width, tex_diff.height, P2D);
  tex_diff_pg.beginDraw();
  tex_diff_pg.clear();
  tex_diff_pg.image(tex_diff, 0,0);
  tex_diff_pg.endDraw();
  
  tex_norm_pg = createGraphics(tex_norm.width, tex_norm.height, P2D);
  tex_norm_pg.beginDraw();
  tex_norm_pg.clear();
  tex_norm_pg.image(tex_norm, 0,0);
  tex_norm_pg.endDraw();
}


void draw()
{
  background(127);
  
  /*
  // Test vertex shader
  shader(tex);
  PImage img = tex_norm_pg;
  translate(mouseX, mouseY);
  rotate( (mouseX + mouseY) * 0.01 );
  image(img, 0, 0);
  resetShader();
  */
  
  
  // Test more complicated stuff
  
  // Define transforms and data
  PImage imgD = tex_diff_pg;
  PImage imgN = tex_norm_pg;
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
  /*
  // Wipe buffer
  deferLight.beginDraw();  deferLight.clear();  deferLight.endDraw();
  // Light 1
  deferLight.beginDraw();
  //deferLight.translate(pos1.x, pos1.y);  deferLight.rotate(ang);  deferLight.translate(pos2.x, pos2.y);
  deferLight.shader(tex_deferLighting);
  tex_deferLighting.set("self", deferLight);
  tex_deferLighting.set("resolution", (float)deferLight.width, (float)deferLight.height);
  tex_deferLighting.set("lightPosition", posLight.x, posLight.y, posLight.z);
  tex_deferLighting.set("lightBrightness", 0.1);
  tex_deferLighting.set("lightFalloffPower", 2.0);
  tex_deferLighting.set("lightSpecularPower", 2.0);
  tex_deferLighting.set("lightSpecularBlend", 1.0);
  tex_deferLighting.set("lightColor", 1.0,0.5,0.25,1.0);
  deferLight.image(deferNorm, 0,0);
  deferLight.endDraw();
  // Second light test
  tex_deferLighting.set("lightColor", 0.25,0.5,1.0,1.0);
  tex_deferLighting.set("lightPosition", 0.0, 1.0, 0.5);
  deferLight.beginDraw();
  deferLight.image(deferNorm, 0,0);
  deferLight.endDraw();
  // Further light tests
  Iterator iPos = lights.iterator();
  Iterator iCol = lightCols.iterator();
  while( iPos.hasNext() )
  {
    PVector lpos = (PVector) iPos.next();
    PVector lcol = (PVector) iCol.next();
    tex_deferLighting.set("lightBrightness", 0.0001);
    tex_deferLighting.set("lightPosition", lpos.x, lpos.y, lpos.z);
    tex_deferLighting.set("lightColor", lcol.x, lcol.y, lcol.z, 1.0);
    deferLight.beginDraw();
    deferLight.image(deferNorm, 0,0);
    deferLight.endDraw();
  }
  */
  
  //Update light buffer
  /*
  bufferLightPos.beginDraw();
  bufferLightPos.loadPixels();
  bufferLightPos.pixels[0] = color(255.0 * mouseX / (float)width,  255 * (1 - mouseY / (float)height), 8, 255);
  bufferLightPos.updatePixels();
  bufferLightPos.endDraw();
  */
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
  //tex_deferLightingImgdata.set("lightPosition", posLight.x, posLight.y, posLight.z);
  //tex_deferLightingImgdata.set("lightColor", 1.0,0.5,0.25,1.0);
  //tex_deferLightingImgdata.set("lightBrightness", 1.0 / (bufferRes.x * bufferRes.y) );
  tex_deferLightingImgdata.set("lightFalloffPower", 2.0);
  tex_deferLightingImgdata.set("lightSpecularPower", 4.0);
  tex_deferLightingImgdata.set("lightSpecularBlend", deferSpec);
  tex_deferLightingImgdata.set("lightBufferDimensions", (float)bufferLightPos.width, (float)bufferLightPos.height);
  //tex_deferLightingImgdata.set("lightPosBuffer", bufferLightPos);
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
  
  // Draw to emit buffer
  
  // Bloom emit buffer
  
  // Fold down buffers
  /*
  image(deferDiff, 0,0);
  //image(deferNorm, 0,0);
  //blend(deferLight, 0,0, deferLight.width, deferLight.height, 0,0, deferLight.width, deferLight.height, HARD_LIGHT);
  image(deferLight, 0,0);
  image(deferEmit, 0,0);
  */
  shader(tex_deferCompositor);
  tex_deferCompositor.set("lightMap", deferLight);
  tex_deferCompositor.set("emitMap", deferEmit);
  image(deferDiff, 0,0);
  resetShader();
  
  
  
  /*
  // Test twoTextures
  translate(mouseX, mouseY);
  PImage img = tex_norm_pg;
  shader_textured_twoTextures.set("extraTexture", img);
  shader_textured_twoTextures.set("resolution", (float)img.width, (float)img.height);
  shader_textured_twoTextures.set("correcterMult", 1.0, 1.0);
  shader_textured_twoTextures.set("correcterAdd", 0.0, ( (float)img.height/(float)height) - 1.0 );
  float[] mat = {  1.0, 0.0, 0.0,
                   0.0, 1.0, 0.0,
                   0.0, 0.0, 1.0  };
  shader_textured_twoTextures.set("customMatrix", mat );
  
  shader(shader_textured_twoTextures);
  image(tex_diff_pg, 0,0, tex_diff_pg.width, tex_diff_pg.height);
  resetShader();
  */
  
  
  // Make coords
  /*
  float lightX = 512 * ( 0.5 + 0.5 * sin(frameCount * 0.05) );
  float lightY = 512 * ( 0.5 + 0.5 * cos(frameCount * 0.033) );
  */
  /*
  float lightX = mouseX;
  float lightY = mouseY;
  
  // Test crude normal shader
  shader_textured_crudeNormal.set("resolution", (float)sprite_buffer2.width, (float)sprite_buffer2.height);
  shader_textured_crudeNormal.set("poi", lightX / (float)sprite_buffer2.width,
                                         1.0 - lightY / (float)sprite_buffer2.height,
                                         1.0);
  shader_textured_crudeNormal.set("specPower", 4.0);
  shader_textured_crudeNormal.set("light_falloff", 2.0);
  shader_textured_crudeNormal.set("light_brightness", 1.0);
  
  sprite_buffer2.beginDraw();
  sprite_buffer2.clear();
  sprite_buffer2.shader(shader_textured_crudeNormal);
  sprite_buffer2.image(tex_norm,  0, 0,  sprite_buffer2.width, sprite_buffer2.height);
  sprite_buffer2.resetShader();
  sprite_buffer2.endDraw();
  
  // Diffuse underpass
  pushMatrix();
  translate(0, tex_diff.height);
  scale(1,-1);
  image(tex_diff, 0,0);
  popMatrix();
  
  // Apply normal light
  blend(sprite_buffer2, 0,0, sprite_buffer2.width, sprite_buffer2.height, 0,0, sprite_buffer2.width, sprite_buffer2.height, MULTIPLY);
  
  
  // Display source
  pushMatrix();
  translate(512, tex_diff.height);
  scale(0.5,-0.5);
  image(tex_norm, 0,0);
  translate(0, 512);
  image(tex_diff, 0,0);
  popMatrix();
  */
  
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
