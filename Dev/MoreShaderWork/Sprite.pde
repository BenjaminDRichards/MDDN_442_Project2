class Sprite
// An image with a transform node and coverage data
{
  DAGTransform transform;
  PImage imgDiff, imgNorm, imgSpec, imgEmit, imgWarp;
  float alphaDiff, alphaNorm, alphaSpec, alphaEmit, alphaWarp;
  float coverageX, coverageY, centerX, centerY;
  
  
  Sprite(DAGTransform transform, PImage imgDiff, float coverageX, float coverageY, float centerX, float centerY)
  {
    this.transform = transform;
    this.imgDiff = imgDiff;
    this.coverageX = coverageX;
    this.coverageY = coverageY;
    this.centerX = centerX;
    this.centerY = centerY;
    
    alphaDiff = 1.0;
    alphaNorm = 1.0;
    alphaSpec = 1.0;
    alphaEmit = 1.0;
    alphaWarp = 0.0;
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
}
// Sprite
