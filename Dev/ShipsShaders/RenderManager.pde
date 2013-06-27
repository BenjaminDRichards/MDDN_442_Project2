import java.util.*;

class RenderManager
// Handles all the complicated parts of a multipass multishader render pipeline
{
  PGraphics bDiffuse, bNormal, bSpecular, bLight, bEmissive, bWarp, bOutput, bBackground;
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
    bBackground = createGraphics(rx, ry, P2D);
    
    // Initialise shaders
    shaderNorm = loadShader("shaders/tex_normDeferrer.frag.glsl", "shaders/tex.vert.glsl");
    shaderLight = loadShader("shaders/tex_lightByImage.frag.glsl", "shaders/tex.vert.glsl");
    shaderComp = loadShader("shaders/tex_deferCompositor.frag.glsl", "shaders/tex.vert.glsl");
    
    // Fill background
    bBackground.beginDraw();
    bBackground.background(64);
    bBackground.tint(255,128);
    bBackground.image(tex_backdrop, 0,0, bBackground.width, bBackground.height);
    bBackground.endDraw();
    
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
      PVector scaleFactor = s.transform.getLocalScale();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bDiffuse.tint(s.tintDiff);
      drawImage( bDiffuse, s.getDiffuse(), pos, ang, scaleFactor, res, offset );
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
      PVector scaleFactor = s.transform.getLocalScale();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bSpecular.tint(s.tintSpec);
      drawImage( bSpecular, s.getSpecular(), pos, ang, scaleFactor, res, offset );
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
      PVector scaleFactor = s.transform.getLocalScale();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bEmissive.tint(s.tintEmit);
      drawImage( bEmissive, s.getEmissive(), pos, ang, scaleFactor, res, offset );
    }
    bEmissive.endDraw();
    
    
    // Normal pass
    bNormal.beginDraw();
    bNormal.clear();
    Iterator iN = sprites.iterator();
    while( iN.hasNext() )
    {
      Sprite s = (Sprite) iN.next();
      if( s.getNormal() == null )  continue;
      // Decode geometry
      PVector pos = s.transform.getWorldPosition();
      float ang = s.transform.getWorldRotation();
      PVector scaleFactor = s.transform.getLocalScale();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bNormal.tint(s.tintNorm);
      // SET SHADER
      bNormal.shader(shaderNorm);
      shaderNorm.set("worldAngle", ang);
      drawImage( bNormal, s.getNormal(), pos, ang, scaleFactor, res, offset );
    }
    bNormal.resetShader();
    bNormal.endDraw();
    
    
    // Warp pass
    bWarp.beginDraw();
    // Set default state
    bWarp.pushStyle();
    //bWarp.background(127, 127, 255);
    bWarp.shader(shaderNorm);
    shaderNorm.set("worldAngle", 0.0);
    bWarp.image(tex_warpBackdrop, 0,0, bWarp.width, bWarp.height);
    bWarp.popStyle();
    // Sprites
    Iterator iW = sprites.iterator();
    while( iW.hasNext() )
    {
      Sprite s = (Sprite) iW.next();
      if( s.getWarp() == null )  continue;
      // Decode geometry
      PVector pos = s.transform.getWorldPosition();
      float ang = s.transform.getWorldRotation();
      PVector scaleFactor = s.transform.getLocalScale();
      PVector res = new PVector(s.coverageX, s.coverageY);
      PVector offset = new PVector(s.coverageX * s.centerX, s.coverageY * s.centerY);
      // Render
      bWarp.pushStyle();
      //bWarp.tint(s.tintWarp);
      bWarp.tint(255, alpha(s.tintWarp) );
      // SET SHADER
      bWarp.shader(shaderNorm);
      shaderNorm.set("worldAngle", ang);
      drawImage( bWarp, s.getWarp(), pos, ang, scaleFactor, res, offset );
      bWarp.popStyle();
    }
    bWarp.resetShader();
    bWarp.endDraw();
    
    
    // Apply lights
    bLight.beginDraw();
    bLight.clear();
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
    shaderComp.set("backgroundMap", bBackground);
    shaderComp.set("aspectRatioCorrection", bOutput.height / (float) bOutput.width,  1.0);
    bOutput.shader(shaderComp);
    bOutput.image(bDiffuse, 0,0, bOutput.width, bOutput.height);
    bOutput.resetShader();
    
    
    // Clear buffers for next frame
    sprites.clear();
    lights.clear();
  }
  // finaliseRender
  
  
  public void drawImage(PGraphics canvas, PImage img, PVector pos, float ang, PVector scaleFactor, PVector res, PVector offset)
  {
    // Coordinate conversion: from percentile to window size
    pos = new PVector( fromPercentX(pos.x), fromPercent(pos.y) );  // Note that this uses fromPercentX, as it's screen space
    offset = new PVector( fromPercent(offset.x), fromPercent(offset.y) );
    res = new PVector( fromPercent(res.x), fromPercent(res.y) );
    
    
    canvas.pushMatrix();
    canvas.translate(pos.x, pos.y);
    canvas.rotate(ang);
    canvas.scale(scaleFactor.x, scaleFactor.y);
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
