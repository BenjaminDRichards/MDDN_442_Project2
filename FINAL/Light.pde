class Light
// Contains data used for light rendering
// It does render itself
// But the shader must be prepared for rendering:
//   this doesn't set additive blending,
//   or start/end drawing.
{
  // Mode
  int mode;
  
  public static final int MODE_POINT = 0;
  public static final int MODE_DIRECTIONAL = 1;
  
  // Point data
  DAGTransform transform;
  float specularPower, lightBrightness;
  PVector lightColor;
  float mDiameter;
  float mBrightToDiam;
  // Light stencil
  PImage stencil;
  
  // Directional data
  PGraphics filler;
  PVector dir;
  
  
  Light(DAGTransform transform, float lightBrightness, color lightColor)
  {
    mode = MODE_POINT;
    
    
    // Point defaults
    
    this.transform = transform;
    specularPower = 4.0;
    this.lightColor = new PVector( red(lightColor) / 255.0, green(lightColor) / 255.0, blue(lightColor) / 255.0 );
    
    mBrightToDiam = 512;  // Trial and error indicates this is most pleasing
    
    stencil = lightStencil;  // Loaded externally
    
    // Compute appropriate diameter for brightness
    setBrightness(lightBrightness);
  }
  
  
  public void render(PImage normalBuffer, PImage specularBuffer, PGraphics lightBuffer, PShader shader)
  {
    switch(mode)
    {
      case MODE_POINT:
        renderPoint(normalBuffer, specularBuffer, lightBuffer, shader);
        break;
      case MODE_DIRECTIONAL:
        renderDirectional(normalBuffer, specularBuffer, lightBuffer, shader);
        break;
      default:
        break;
    }
  }
  // render
  
  
  public void renderPoint(PImage normalBuffer, PImage specularBuffer, PGraphics lightBuffer, PShader shader)
  {
    // Set shader options
    lightBuffer.shader(shader);
    shader.set("lightSpecularPower", specularPower);
    shader.set("lightColor", lightColor.x, lightColor.y, lightColor.z, 1.0);
    float scaledBrightness = lightBrightness * transform.getLocalScale().x;  // This means light brightness can scale.
    shader.set("lightBrightness", scaledBrightness);
    //shader.set("worldAngle", transform.getWorldRotation() );
    shader.set("normalMap", normalBuffer);
    shader.set("lightSpecularMap", specularBuffer);
    
    // Geometry
    PVector pos = transform.getWorldPosition();
    
    // Convert from percentiles
    pos = new PVector( fromPercentX(pos.x), fromPercentY(pos.y) );
    
    PVector stencilCorner = new PVector(pos.x - mDiameter / 2, pos.y - mDiameter / 2);
    // Derive coordinates relative to submaps
    // Because OpenGL measures from the bottom of the screen, our Y values are a little unusual
    PVector mapScale = new PVector(mDiameter / (float)normalBuffer.width,
                                   -mDiameter / (float)normalBuffer.height);
    // The image is now correctly proportioned, but in negative space and must be corrected by (0, 1)
    // Y values are measured from the bottom of the screen now
    PVector mapOffset = new PVector( stencilCorner.x / (float)normalBuffer.width,
                                     1.0 - stencilCorner.y / (float)normalBuffer.height );
    // Set shader parameters
    shader.set("mapCoordScale", mapScale.x, mapScale.y);
    shader.set("mapCoordOffset", mapOffset.x, mapOffset.y);
    
    // Render
    lightBuffer.pushMatrix();
    lightBuffer.scale(lightBuffer.width / (float) normalBuffer.width,  lightBuffer.height / (float) normalBuffer.height);
    lightBuffer.translate(pos.x, pos.y);
    //lightBuffer.rotate( transform.getWorldRotation() );
    lightBuffer.translate( -mDiameter / 2.0,  -mDiameter / 2.0 );
    lightBuffer.image(stencil, 0, 0, mDiameter, mDiameter);
    lightBuffer.popMatrix();
  }
  // renderPoint
  
  
  public void renderDirectional(PImage normalBuffer, PImage specularBuffer, PGraphics lightBuffer, PShader shader)
  {
    // Set shader options
    lightBuffer.shader(shader);
    shader.set("lightSpecularPower", specularPower);
    shader.set("lightColor", lightColor.x, lightColor.y, lightColor.z, 1.0);
    float scaledBrightness = lightBrightness * transform.getLocalScale().x;  // This means light brightness can scale.
    shader.set("lightBrightness", scaledBrightness);
    //shader.set("worldAngle", 0.0 );
    shader.set("normalMap", normalBuffer);
    shader.set("lightSpecularMap", specularBuffer);
    
    // Set shader parameters
    shader.set("mapCoordScale", 1.0, 1.0);
    shader.set("mapCoordOffset", 0.0, 0.0);
    
    // Render
    lightBuffer.image(filler, 0, 0, lightBuffer.width, lightBuffer.height);
  }
  // render
  
  
  public void setBrightness(float b)
  {
    lightBrightness = b;
    mDiameter = sqrt(b) * mBrightToDiam;
  }
  // setBrightness
  
  
  public void makeDirectional(PVector dir)
  {
    mode = MODE_DIRECTIONAL;
    
    this.dir = dir;
    
    filler = createGraphics(8,8, P2D);
    setDir(dir);
  }
  // makeDirectional
  
  
  public void setDir(PVector direction)
  {
    dir = direction.get();
    dir.normalize();
    // Build colour - note that Y is inverse
    color texDir = color(255.0 * (-dir.x * 0.5 + 0.5), 255.0 * (dir.y * 0.5 + 0.5), 255.0 * (-dir.z * 0.5 + 0.5), 255.0);
    filler.beginDraw();
    filler.background(texDir);
    filler.endDraw();
  }
  // setDir
}
// Light
