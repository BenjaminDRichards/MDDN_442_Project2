class Sprite
// An image with a transform node and coverage data
{
  DAGTransform transform;
  PImage imgDiff, imgNorm, imgSpec, imgEmit, imgWarp;
  color tintDiff, tintNorm, tintSpec, tintEmit, tintWarp;
  color masterTintDiff, masterTintNorm, masterTintSpec, masterTintEmit, masterTintWarp;
  float coverageX, coverageY, centerX, centerY;
  
  
  Sprite(DAGTransform transform, PImage imgDiff, float coverageX, float coverageY, float centerX, float centerY)
  {
    this.transform = transform;
    this.imgDiff = imgDiff;
    this.coverageX = coverageX;
    this.coverageY = coverageY;
    this.centerX = centerX;
    this.centerY = centerY;
    
    tintDiff = color(255,255);
    tintNorm = color(255,255);
    tintSpec = color(255,255);
    tintEmit = color(255,255);
    tintWarp = color(255,0);    // Warp is disabled by default
    
    masterTintDiff = color(255,255);
    masterTintNorm = color(255,255);
    masterTintSpec = color(255,255);
    masterTintEmit = color(255,255);
    masterTintWarp = color(255,255);
  }
  
  
  public void render(PGraphics canvas)
  {
    canvas.pushMatrix();
    canvas.translate(transform.getWorldPosition().x, transform.getWorldPosition().y);
    canvas.rotate(transform.getWorldRotation());
    canvas.scale(transform.getWorldScale().x, transform.getWorldScale().y);
    canvas.image(imgDiff,  coverageX * centerX, coverageY * centerY,  coverageX, coverageY);
    canvas.popMatrix();
  }
  // render
  
  public void render()
  // Helper which draws to the main screen
  {
    render(g);
  }
  // render
  
  
  public void setDiffuse(PImage img)  {  imgDiff = img;  }
  public void setNormal(PImage img)  {  imgNorm = img;  }
  public void setSpecular(PImage img)  {  imgSpec = img;  }
  public void setEmissive(PImage img)  {  imgEmit = img;  }
  public void setWarp(PImage img)  {  imgWarp = img;  }
  
  public PImage getDiffuse()  {  return( imgDiff );  }
  public PImage getNormal()  {  return( imgNorm );  }
  public PImage getSpecular()  {  return( imgSpec );  }
  public PImage getEmissive()  {  return( imgEmit );  }
  public PImage getWarp()  {  return( imgWarp );  }
  
  public color getDiffuseTint()  {  return( multColors( tintDiff, masterTintDiff ) );  }
  public color getNormalTint()  {  return( multColors( tintNorm, masterTintNorm ) );  }
  public color getSpecularTint()  {  return( multColors( tintSpec, masterTintSpec ) );  }
  public color getEmissiveTint()  {  return( multColors( tintEmit, masterTintEmit ) );  }
  public color getWarpTint()  {  return( multColors( tintWarp, masterTintWarp ) );  }
  
  private color multColors(color col1, color col2)
  {
    color c = color( red(col1) * red(col2) / 255.0,
                     green(col1) * green(col2) / 255.0,
                     blue(col1) * blue(col2) / 255.0,
                     alpha(col1) * alpha(col2) / 255.0 );
    return( c );
  }
}
// Sprite
