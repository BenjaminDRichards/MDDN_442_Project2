import java.util.*;

class RenderManager
// Handles all the complicated parts of a multipass multishader render pipeline
{
  PGraphics bDiffuse, bNormal, bSpecular, bLight, bEmissive, bOutput;
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
      drawDiff( s.getDiffuse(), pos, ang, res, offset );
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
      drawSpecular( s.getSpecular(), pos, ang, res, offset );
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
      drawEmissive( s.getEmissive(), pos, ang, res, offset );
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
      drawNormal( s.getNormal(), pos, ang, res, offset );
    }
    bNormal.resetShader();
    bNormal.endDraw();
    
    
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
    bOutput.shader(shaderComp);
    bOutput.image(bDiffuse, 0,0, bOutput.width, bOutput.height);
    bOutput.resetShader();
    
    
    // Clear buffers for next frame
    sprites.clear();
    lights.clear();
  }
  // finaliseRender
  
  
  public void drawDiff(PImage img, PVector pos, float ang, PVector res, PVector offset)
  {
    // Coordinate conversion goes here
    
    bDiffuse.pushMatrix();
    bDiffuse.translate(pos.x, pos.y);
    bDiffuse.rotate(ang);
    bDiffuse.translate(offset.x, offset.y);
    bDiffuse.image(img, 0,0, res.x, res.y);
    bDiffuse.popMatrix();
  }
  // drawDiff
  
  
  public void drawSpecular(PImage img, PVector pos, float ang, PVector res, PVector offset)
  {
    // Coordinate conversion goes here
    
    bSpecular.pushMatrix();
    bSpecular.translate(pos.x, pos.y);
    bSpecular.rotate(ang);
    bSpecular.translate(offset.x, offset.y);
    bSpecular.image(img, 0,0, res.x, res.y);
    bSpecular.popMatrix();
  }
  // drawSpecular
  
  
  public void drawEmissive(PImage img, PVector pos, float ang, PVector res, PVector offset)
  {
    // Coordinate conversion goes here
    
    bEmissive.pushMatrix();
    bEmissive.translate(pos.x, pos.y);
    bEmissive.rotate(ang);
    bEmissive.translate(offset.x, offset.y);
    bEmissive.image(img, 0,0, res.x, res.y);
    bEmissive.popMatrix();
  }
  // drawEmissive
  
  
  public void drawNormal(PImage img, PVector pos, float ang, PVector res, PVector offset)
  {
    // Coordinate conversion goes here
    
    // Shader effects
    shaderNorm.set("worldAngle", ang);
    
    bNormal.pushMatrix();
    bNormal.translate(pos.x, pos.y);
    bNormal.rotate(ang);
    bNormal.translate(offset.x, offset.y);
    bNormal.image(img, 0,0, res.x, res.y);
    bNormal.popMatrix();
  }
  // drawNormal
  
  
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
