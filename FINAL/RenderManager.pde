import java.util.*;

class RenderManager
// Handles all the complicated parts of a multipass multishader render pipeline
{
  PGraphics bDiffuse, bNormal, bSpecular, bLight, bEmissive, bWarp, bOutput, bBackground, bForeground, bScreenWarp;
  PShader shaderNorm, shaderLight, shaderComp, shaderBloom, shaderAdd, shaderScreen;
  ArrayList sprites, lights;
  PImage fullBackground, fullDiffuse, fullNormal, fullSpecular, fullEmissive, fullWarp, fullLight;  // Background fill sources
  
  // Bloom segment
  boolean doBloom;
  int bloomScale;
  PGraphics bBloom, bBloomHorizontal, bBloomVertical, bBloomCache;
  
  
  RenderManager(PGraphics bOutput)
  {
    this.bOutput = bOutput;
    
    // Set buffers to match output dimensions
    int rx = bOutput.width;
    int ry = bOutput.height;
    //int rxLow = rx / 2;
    //int ryLow = ry / 2;
    bDiffuse = createGraphics(rx, ry, P2D);
    bNormal = createGraphics(rx, ry, P2D);
    bSpecular = createGraphics(rx, ry, P2D);
    bLight = createGraphics(rx, ry, P2D);
    bEmissive = createGraphics(rx, ry, P2D);
    bWarp = createGraphics(rx, ry, P2D);
    bBackground = createGraphics(rx, ry, P2D);
    bForeground = createGraphics(rx, ry, P2D);
    bScreenWarp = createGraphics(rx, ry, P2D);
    
    // Initialise shaders
    shaderNorm = loadShader("shaders/tex_normDeferrer.frag.glsl", "shaders/tex.vert.glsl");
    shaderLight = loadShader("shaders/tex_lightByImage.frag.glsl", "shaders/tex.vert.glsl");
    shaderComp = loadShader("shaders/tex_deferCompositor.frag.glsl", "shaders/tex.vert.glsl");
    shaderBloom = loadShader("shaders/tex_bloomMax.frag.glsl", "shaders/tex.vert.glsl");
    shaderAdd = loadShader("shaders/tex_add.frag.glsl", "shaders/tex.vert.glsl");
    shaderScreen = loadShader("shaders/tex_screen.frag.glsl", "shaders/tex.vert.glsl");
    
    // Fill flats
    bBackground.beginDraw();
    bBackground.image(tex_backdrop, 0,0, bBackground.width, bBackground.height);
    bBackground.endDraw();
    bForeground.beginDraw();
    bForeground.clear();
    bForeground.endDraw();
    bScreenWarp.beginDraw();
    bScreenWarp.image(tex_warpBackdrop, 0,0, bBackground.width, bBackground.height);
    bScreenWarp.endDraw();
    bWarp.beginDraw();
    bWarp.background(127,127,255);
    bWarp.endDraw();
    
    // Init asset buffers
    sprites = new ArrayList();
    lights = new ArrayList();
    
    // Init necessary fullscreen texture spaces
    fullBackground = tex_flatNull;
    
    // Prep bloom segment
    doBloom = false;
    bloomScale = 8;
    float bloomMapScale = ry / (720.0 * bloomScale);
    int rBloomX = int( min(rx * bloomMapScale,  320.0) );
    int rBloomY = int( min(ry * bloomMapScale,  180.0) );
    bBloom = createGraphics( rBloomX, rBloomY, P2D );
    bBloomHorizontal = createGraphics( rBloomX, rBloomY, P2D );
    bBloomVertical = createGraphics( rBloomX, rBloomY, P2D );
    bBloomCache = createGraphics(rx, ry, P2D);
    println("BLOOM RESOLUTION [ " + bBloom.width + ", " + bBloom.height + " ]");
  }
  
  
  public void render()
  {
    // Apply sprites
    // These must be iterated several times for different buffers
    
    
    // Diffuse pass
    bDiffuse.beginDraw();
    bDiffuse.clear();
    // Fullscreen pass
    if(fullDiffuse != null)
    {
      bDiffuse.image(fullDiffuse, 0,0, bDiffuse.width, bDiffuse.height);
    }
    // Sprites
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
      bDiffuse.pushStyle();
      bDiffuse.tint( s.getDiffuseTint() );
      drawImage( bDiffuse, s.getDiffuse(), pos, ang, scaleFactor, res, offset );
      bDiffuse.popStyle();
    }
    bDiffuse.endDraw();
    
    
    // Specular pass
    bSpecular.beginDraw();
    bSpecular.clear();
    // Fullscreen pass
    if(fullSpecular != null)
    {
      bSpecular.image(fullSpecular, 0,0, bSpecular.width, bSpecular.height);
    }
    // Sprites
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
      bSpecular.pushStyle();
      bSpecular.tint( s.getSpecularTint() );
      drawImage( bSpecular, s.getSpecular(), pos, ang, scaleFactor, res, offset );
      bSpecular.popStyle();
    }
    bSpecular.endDraw();
    
    
    // Emissive pass
    bEmissive.beginDraw();
    bEmissive.clear();
    // Fullscreen pass
    if(fullEmissive != null)
    {
      bEmissive.image(fullEmissive, 0,0, bEmissive.width, bEmissive.height);
    }
    // Sprites
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
      bEmissive.pushStyle();
      bEmissive.tint( s.getEmissiveTint() );
      drawImage( bEmissive, s.getEmissive(), pos, ang, scaleFactor, res, offset );
      bEmissive.popStyle();
    }
    bEmissive.endDraw();
    
    
    // Normal pass
    bNormal.beginDraw();
    bNormal.clear();
    // Fullscreen pass
    if(fullNormal != null)
    {
      bNormal.image(fullNormal, 0,0, bNormal.width, bNormal.height);
    }
    // Sprites
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
      bNormal.pushStyle();
      bNormal.tint( s.getNormalTint() );
      // SET SHADER
      bNormal.shader(shaderNorm);
      shaderNorm.set("worldAngle", ang);
      drawImage( bNormal, s.getNormal(), pos, ang, scaleFactor, res, offset );
      bNormal.popStyle();
    }
    bNormal.resetShader();
    bNormal.endDraw();
    
    
    // Warp pass
    bWarp.beginDraw();
    // Fullscreen pass
    if(fullWarp != null)
    {
      bWarp.pushStyle();
      bWarp.shader(shaderNorm);
      //bWarp.tint(255, 192);
      shaderNorm.set("worldAngle", 0.0);
      bWarp.image(fullWarp, 0,0, bWarp.width, bWarp.height);
      bWarp.popStyle();
    }
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
      //bWarp.tint( s.getWarpTint() );
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
    // Fullscreen pass
    if(fullLight != null)
    {
      // This is NOT run thru the shader
      bLight.image(fullLight, 0,0, bLight.width, bLight.height);
    }
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
    shaderComp.set("foregroundMap", bForeground);
    shaderComp.set("screenWarpMap", bScreenWarp);
    shaderComp.set("aspectRatioCorrection", bOutput.height / (float) bOutput.width,  1.0);
    if( !bOutput.equals(g) )  bOutput.beginDraw();
    bOutput.shader(shaderComp);
    bOutput.image(bDiffuse, 0,0, bOutput.width, bOutput.height);
    bOutput.resetShader();
    if( !bOutput.equals(g) )  bOutput.endDraw();
    
    
    // Run bloom shader
    if(doBloom)
    {
      // Parameters
      float bloomStep = 4.0 / 720.0;
      float bloomFallPower = 3.5;
      
      // Cache graphics
      bBloomCache.beginDraw();
      bBloomCache.image(bOutput, 0,0, bBloomCache.width, bBloomCache.height);
      bBloomCache.endDraw();
      
      // Compute horizontal bloom map
      bBloomHorizontal.beginDraw();
      //bBloomHorizontal.clear();
      bBloomHorizontal.shader(shaderBloom);
      shaderBloom.set("bloomFallPower", bloomFallPower);
      shaderBloom.set("bloomSteps", 8.0, 0.0);
      shaderBloom.set("bloomDist",  bloomStep * bOutput.height / (float)bOutput.width,   bloomStep);
      bBloomHorizontal.image(bOutput, 0,0, bBloomHorizontal.width, bBloomHorizontal.height);
      //bBloomHorizontal.resetShader();
      bBloomHorizontal.endDraw();
      
      // Compute vertical bloom map
      bBloomVertical.beginDraw();
      //bBloomVertical.clear();
      bBloomVertical.shader(shaderBloom);
      shaderBloom.set("bloomFallPower", bloomFallPower);
      shaderBloom.set("bloomSteps", 0.0, 4.0);
      shaderBloom.set("bloomDist",  bloomStep * bOutput.height / (float)bOutput.width,   bloomStep);
      bBloomVertical.image(bOutput, 0,0, bBloomVertical.width, bBloomVertical.height);
      //bBloomVertical.resetShader();
      bBloomVertical.endDraw();
      
      // Combine bloom maps
      bBloom.beginDraw();
      bBloom.shader(shaderScreen);
      shaderScreen.set("texture2", bBloomVertical);
      bBloom.image(bBloomHorizontal, 0,0, bBloomVertical.width, bBloomVertical.height);
      bBloom.endDraw();
      
      /*
      bBloom.beginDraw();
      bBloom.clear();
      bBloom.shader(shaderBloom);
      shaderBloom.set("bloomFallPower", bloomFallPower);
      shaderBloom.set("bloomSteps", 8.0, 4.0);
      shaderBloom.set("bloomDist",  bloomStep * bOutput.height / (float)bOutput.width,   bloomStep);
      bBloom.image(bOutput, 0,0, bBloom.width, bBloom.height);
      bBloom.endDraw();
      */
      
      // Apply bloom map
      if( !bOutput.equals(g) )  bOutput.beginDraw();
      bOutput.shader(shaderScreen);
      shaderScreen.set("texture2", bBloomCache);
      bOutput.image(bBloom, 0,0, bOutput.width, bOutput.height);
      bOutput.resetShader();
      if( !bOutput.equals(g) )  bOutput.endDraw();
    }
    
    
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
