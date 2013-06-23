import java.util.*;

class RenderManager
// Handles all the complicated parts of a multipass multishader render pipeline
{
  PGraphics bDiffuse, bNormal, bSpecular, bLight, bEmissive, bWarp, bOutput;
  PShader shaderNorm, shaderLight, shaderComp;
  ArrayList sprites, lights;
  
  
  RenderManager(PGraphics bOutput)
  {
    this.bOutput = bOutput;
    
    // Set buffers to match output dimensions
    int rx = bOutput.width;
    int ry = bOutput.height;
    bDiffuse = createGraphics(rx, ry, P2D);
    bNormal = createGraphics(rx, ry, P2D);
    bSpecular = createGraphics(rx, ry, P2D);
    bLight = createGraphics(rx, ry, P2D);
    bEmissive = createGraphics(rx, ry, P2D);
    bWarp = createGraphics(rx, ry, P2D);
    
    // Initialise shaders
    shaderNorm = loadShader("tex_normDeferrer.frag.glsl", "tex.vert.glsl");
    shaderLight = loadShader("tex_lightByImage.frag.glsl", "tex.vert.glsl");
    shaderComp = loadShader("tex_deferCompositor.frag.glsl", "tex.vert.glsl");
    
    // Init asset buffers
    sprites = new ArrayList();
    lights = new ArrayList();
  }
  
  
  public void render()
  {
    // Apply sprites
    // These must be iterated several times for different buffers
    
    // Diffuse pass
    bDiffuse.beginDraw();
    bDiffuse.clear();
    Iterator iD = sprites.iterator();
    while( iD.hasNext() )
    {
      Sprite s = (Sprite) iD.next();
      if( s.getDiffuse() == null )  continue;
      // Decode geometry
      PVector pos = s.transform.getWorldPosition();
      float ang = s.transform.getWorldRotation();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bDiffuse.tint(255, 255 * s.alphaDiff);
      drawImage( bDiffuse, s.getDiffuse(), pos, ang, res, offset );
    }
    bDiffuse.endDraw();
    
    
    // Specular pass
    bSpecular.beginDraw();
    bSpecular.clear();
    Iterator iS = sprites.iterator();
    while( iS.hasNext() )
    {
      Sprite s = (Sprite) iS.next();
      if( s.getSpecular() == null )  continue;
      // Decode geometry
      PVector pos = s.transform.getWorldPosition();
      float ang = s.transform.getWorldRotation();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bSpecular.tint(255, 255 * s.alphaSpec);
      drawImage( bSpecular, s.getSpecular(), pos, ang, res, offset );
    }
    bSpecular.endDraw();
    
    
    // Emissive pass
    bEmissive.beginDraw();
    bEmissive.clear();
    Iterator iE = sprites.iterator();
    while( iE.hasNext() )
    {
      Sprite s = (Sprite) iE.next();
      if( s.getEmissive() == null )  continue;
      // Decode geometry
      PVector pos = s.transform.getWorldPosition();
      float ang = s.transform.getWorldRotation();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bEmissive.tint(255, 255 * s.alphaEmit);
      drawImage( bEmissive, s.getEmissive(), pos, ang, res, offset );
    }
    bEmissive.endDraw();
    
    
    // Normal pass
    bNormal.beginDraw();
    // SET SHADER
    bNormal.shader(shaderNorm);
    bNormal.clear();
    Iterator iN = sprites.iterator();
    while( iN.hasNext() )
    {
      Sprite s = (Sprite) iN.next();
      if( s.getNormal() == null )  continue;
      // Decode geometry
      PVector pos = s.transform.getWorldPosition();
      float ang = s.transform.getWorldRotation();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bNormal.tint(255, 255 * s.alphaNorm);
      shaderNorm.set("worldAngle", ang);
      drawImage( bNormal, s.getNormal(), pos, ang, res, offset );
    }
    bNormal.resetShader();
    bNormal.endDraw();
    
    /*
    // Test warp shader
    bWarp.beginDraw();
    bWarp.shader(shaderNorm);
    float warpAng = -1.0 + frameCount * 0.01;
    shaderNorm.set("worldAngle", warpAng);
    bWarp.clear();
    
    bWarp.pushMatrix();
    bWarp.translate(256,256);
    bWarp.rotate(warpAng);
    bWarp.translate(-256,-256);
    bWarp.image(tex_cloakNorm, 0,0);
    bWarp.popMatrix();
    
    bWarp.resetShader();
    bWarp.endDraw();
    */
    // Warp pass
    bWarp.beginDraw();
    // SET SHADER
    bWarp.shader(shaderNorm);
    bWarp.clear();
    Iterator iW = sprites.iterator();
    while( iW.hasNext() )
    {
      Sprite s = (Sprite) iW.next();
      if( s.getWarp() == null )  continue;
      // Decode geometry
      PVector pos = s.transform.getWorldPosition();
      float ang = s.transform.getWorldRotation();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bWarp.tint(255, 255 * s.alphaWarp);
      shaderNorm.set("worldAngle", ang);
      drawImage( bWarp, s.getWarp(), pos, ang, res, offset );
    }
    bWarp.resetShader();
    bWarp.endDraw();
    
    
    // Apply lights
    bLight.beginDraw();
    bLight.clear();
    bLight.shader(shaderLight);
    // Set additive fragment blender
    PGL pgl = bLight.beginPGL();
    pgl.blendFunc(PGL.ONE, PGL.ONE);
    // Step through lights
    Iterator iL = lights.iterator();
    while( iL.hasNext() )
    {
      Light lg = (Light) iL.next();
      lg.render(bNormal, bSpecular, bLight, shaderLight);
    }
    // Finalise lights
    endPGL();
    bLight.endDraw();
    
    
    
    // Composite into output map
    shaderComp.set("lightMap", bLight);
    shaderComp.set("emitMap", bEmissive);
    shaderComp.set("warpMap", bWarp);
    shaderComp.set("aspectRatioCorrection", bOutput.height / (float) bOutput.width,  1.0);
    bOutput.shader(shaderComp);
    bOutput.image(bDiffuse, 0,0, bOutput.width, bOutput.height);
    bOutput.resetShader();
    
    
    // Clear buffers for next frame
    sprites.clear();
    lights.clear();
  }
  // finaliseRender
  
  
  public void drawImage(PGraphics canvas, PImage img, PVector pos, float ang, PVector res, PVector offset)
  {
    // Coordinate conversion goes here
    
    canvas.pushMatrix();
    canvas.translate(pos.x, pos.y);
    canvas.rotate(ang);
    canvas.translate(offset.x, offset.y);
    canvas.image(img, 0,0, res.x, res.y);
    canvas.popMatrix();
  }
  
  
  public void addLight(Light light)
  {
    lights.add(light);
  }
  // addLight
  
  
  public void addSprite(Sprite sprite)
  {
    sprites.add(sprite);
  }
  // addSprite
}
// RenderManager
