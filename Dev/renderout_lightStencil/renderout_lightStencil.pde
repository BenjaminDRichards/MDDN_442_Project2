PGraphics stencil;

void setup()
{
  size(256,256,P2D);
  
  // Light stencil
  stencil = createGraphics(width,height, JAVA2D);
  stencil.beginDraw();
  stencil.clear();
  float heightDivisor = 16;  // Higher values create sharper falloff
  PVector lightCentre = new PVector(stencil.width / 2.0, stencil.height / 2.0, stencil.height / heightDivisor);
  for(int y = 0;  y < stencil.height;  y++)
  for(int x = 0;  x < stencil.width;  x++)
  {
    PVector surfaceVec = new PVector(x, y, 0);
    PVector lightVec = PVector.sub(lightCentre, surfaceVec);
    PVector normCol = vectorToTextureNormal(lightVec);
    float aleph = 255.0 * lightCentre.z / lightVec.mag();  // Intensity based on distance
    // Scale down to 0 at the edges
    float alephMod = 1.0 - ( surfaceVec.dist( new PVector(lightCentre.x, lightCentre.y, 0) ) / (stencil.width * 0.5) );
    aleph *= alephMod;
    stencil.set( x, y, color(normCol.x, normCol.y, normCol.z, aleph) );
  }
  
  stencil.save("lightStencil.png");
  
  stencil.endDraw();
  
}


void draw()
{
  background(255);
  image(stencil, 0,0);
}


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
