class Light
// Contains data used for light rendering
// It does render itself
// But the shader must be prepared for rendering:
//   this doesn't set additive blending,
//   or start/end drawing.
{
  // Intrinsic data
  PVector pos;
  float specularPower, lightBrightness;
  PVector lightColor;
  float mDiameter;
  float mBrightToDiam;
  
  // Input/Output Buffers
  //PImage normalBuffer;
  //PImage specularBuffer;
  //PGraphics lightBuffer;
  //PShader shader;
  
  // Light stencil
  PImage stencil;
  
  
  Light(PVector pos, float lightBrightness, color lightColor)
  {
    this.pos = pos;
    specularPower = 4.0;
    this.lightColor = new PVector( red(lightColor) / 255.0, green(lightColor) / 255.0, blue(lightColor) / 255.0 );
    //this.normalBuffer = normalBuffer;
    //this.specularBuffer = specularBuffer;
    //this.lightBuffer = lightBuffer;
    //this.shader = shader;
    
    mBrightToDiam = 32768.0;
    
    stencil = lightStencil;  // Loaded externally
    
    // Compute appropriate diameter for brightness
    setBrightness(lightBrightness);
  }
  
  
  public void render(PImage normalBuffer, PImage specularBuffer, PGraphics lightBuffer, PShader shader)
  {
    // Set shader options
    shader.set("lightSpecularPower", specularPower);
    shader.set("lightColor", lightColor.x, lightColor.y, lightColor.z, 1.0);
    shader.set("lightBrightness", lightBrightness);
    shader.set("normalMap", normalBuffer);
    shader.set("lightSpecularMap", specularBuffer);
    
    // Geometry
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
    lightBuffer.shader(shader);
    lightBuffer.pushMatrix();
    lightBuffer.translate(stencilCorner.x, stencilCorner.y);
    lightBuffer.image(stencil, 0, 0, mDiameter, mDiameter);
    lightBuffer.popMatrix();
    lightBuffer.resetShader();
  }
  // render
  
  
  public void setBrightness(float b)
  {
    lightBrightness = b;
    mDiameter = b * mBrightToDiam;
  }
  // setBrightness
}
// Light
