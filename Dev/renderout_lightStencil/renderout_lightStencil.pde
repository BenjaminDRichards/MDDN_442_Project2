PGraphics stencil;

void setup()
{
  size(256,256,P2D);
  
  /*
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
  */
  
  /*
  // Screen edge warp
  stencil = createGraphics(width, height, JAVA2D);
  stencil.beginDraw();
  stencil.clear();
  PVector center = new PVector(stencil.width / 2, stencil.height / 2);
  float radius = width / 2;
  stencil.loadPixels();
  for(int y = 0;  y < stencil.height;  y++)
  for(int x = 0;  x < stencil.width;  x++)
  {
    PVector aim = new PVector(0,0,1);
    
    // Side curvature
    float edgePower = 8.0;
    PVector pos = new PVector(x, y);
    //float edginess = center.dist(pos) / radius;
    float edginess = 0.0;
    // Left curve
    float leftiness = 1.0 - pow( x / (float)width,  1.0/edgePower );
    PVector curveLeft = new PVector(leftiness, 0,0);
    aim.add(curveLeft);
    edginess = max(0.0, leftiness);
    // Right curve
    float rightiness = 1.0 - pow( 1.0 - (x / (float)width),  1.0/edgePower );
    PVector curveRight = new PVector(-rightiness, 0,0);
    aim.add(curveRight);
    edginess = max(0.0, rightiness);
    // Upper curve
    float uppiness = 1.0 - pow( y / (float)height,  1.0/edgePower );
    PVector curveUp = new PVector(0, -uppiness, 0);
    aim.add(curveUp);
    edginess = max(0.0, uppiness);
    // Bottom curve
    float lowliness = 1.0 - pow( 1.0 - (y / (float)height),  1.0/edgePower );
    PVector curveLow = new PVector(0, lowliness, 0);
    aim.add(curveLow);
    edginess = max(0.0, lowliness);
    
    // Simple noise
    float n = 0.03;
    float nx = noise(x * n,  y * n,  0);
    float ny = noise(0,  y * n,  x * n);
    PVector distortion = new PVector( noise(y * n + ny,  0,  x * n + nx), noise(x * n + ny,  0,  y * n + nx) );
    distortion.sub( new PVector(0.5, 0.5, 0.5) );
    distortion.normalize();
    //distortion.mult( max(0.0,  0.85 - pow(1 - edginess,  1.0/4.0) ) );
    distortion.mult( max(0.0,  0.85 - (1 - edginess) ) );
    distortion.add(aim);
    PVector distColVec = vectorToTextureNormal(distortion);
    color distCol = color(distColVec.x, distColVec.y, distColVec.z, 255);
    
    stencil.pixels[x + y * stencil.width] = distCol;
  }
  stencil.updatePixels();
  stencil.save("windowGlass.png");
  stencil.endDraw();
  */
  
  /*
  // Shockwave
  stencil = createGraphics(width, height, JAVA2D);
  stencil.beginDraw();
  stencil.clear();
  
  PVector flat = new PVector(0,0,1);
  PVector center = new PVector(stencil.width / 2, stencil.height / 2);
  float radius = width / 2;
  
  stencil.loadPixels();
  for(int y = 0;  y < stencil.height;  y++)
  for(int x = 0;  x < stencil.width;  x++)
  {
    PVector pos = new PVector(x, y);
    
    float distFromCenter = center.dist(pos) / radius;
    float tilt1 = pow(distFromCenter, 3.0);
    float tilt2 = pow(1 - distFromCenter, 0.5);
    float tilt = lerp(tilt1, tilt2, distFromCenter);
    
    PVector dir = PVector.sub(pos, center);
    dir.normalize();
    float nx = lerp(flat.x, dir.x, tilt);
    float ny = lerp(flat.y, dir.y, tilt);
    float nz = lerp(flat.z, dir.z, tilt);
    PVector vecTex = vectorToTextureNormal( new PVector(nx, ny, nz) );
    
    stencil.pixels[x + y * stencil.width] = color(vecTex.x, vecTex.y, vecTex.z, 255 * tilt);
  }
  stencil.updatePixels();
  
  stencil.save("shockwave.png");
  stencil.endDraw();
  */
  
  
  // Shockwave 2
  stencil = createGraphics(width, height, JAVA2D);
  stencil.beginDraw();
  stencil.clear();
  
  PVector flat = new PVector(0,0,1);
  PVector center = new PVector(stencil.width / 2, stencil.height / 2);
  float radius = width / 2;
  
  stencil.loadPixels();
  for(int y = 0;  y < stencil.height;  y++)
  for(int x = 0;  x < stencil.width;  x++)
  {
    PVector pos = new PVector(x, y);
    PVector dir = PVector.sub(pos, center);
    dir.normalize();
    float distFromCenter = center.dist(pos) / radius;
    float tilt = pow(1 - distFromCenter, 0.5);
    
    float nx = lerp(dir.x, flat.x, tilt);
    float ny = lerp(dir.y, flat.y, tilt);
    float nz = lerp(dir.z, flat.z, tilt);
    PVector vecTex = vectorToTextureNormal( new PVector(nx, ny, nz) );
    
    stencil.pixels[x + y * stencil.width] = color(vecTex.x, vecTex.y, vecTex.z, 255 * tilt);
  }
  stencil.updatePixels();
  
  stencil.save("shockwave2.png");
  stencil.endDraw();
  
  
  println("Done!");
}


void draw()
{
  background(255);
  image(stencil, 0,0, width, height);
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
