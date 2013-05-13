import java.util.*;

class NormalMap
{
  /*
  This class contains a 2D normal map which can be transformed.
  Because it's per-pixel, it has to manage its own transform matrix.
  Drawing into its own untransformed buffer keeps everything much simpler.
  
  IMPORTANT NOTE:
  Apparently, getting the lightBuffer with image() flips it in Y.
  Instead of
    image(lightBuffer, x, y)
  it might work to use
    pushMatrix();
    translate(x, y + lightBuffer.height);
    scale(1, -1);
    image(lightBuffer, 0, 0);
    popMatrix();
  
  FURTHER NOTE:
  Object Space normals appear to be incompatible with this code.
  Tangent Space normals are A-OK.
  
  */
  
  // Graphics data
  PImage map;
  PGraphics lightBuffer;
  
  // Transform data
  PVector pos;  // The upper left corner of the map
  float ang;
  float scalar;
  float scalar_to_master;
  
  // Lighting data
  ArrayList lightList;
  ArrayList optimalLights;
  
  // Quality parameters
  float OPTIMAL_LIGHT_THRESHOLD;
  
  
  NormalMap(PImage map)
  {
    // Load normal map data
    this.map = map;
    
    regenerateLightMap();
    
    // Setup transforms
    pos = new PVector(0,0,0);
    ang = 0.0;
    scalar = 1.0;
    scalar_to_master = 1.0;
    
    // Setup lights
    lightList = new ArrayList();
    
    OPTIMAL_LIGHT_THRESHOLD = 0.1;
  }
  
  
  void render()
  {
    // Evaluate lights
    // Some lights will be too far away, so let's build an optimised list
    optimalLights = new ArrayList();
    PVector posCentral = pos.get();
    PVector posCentralOffset = new PVector(map.width / 2.0,  map.height / 2.0);
    posCentralOffset.rotate(ang);
    posCentral.add(posCentralOffset.x,  posCentralOffset.y,  0);
    Iterator li = lightList.iterator();
    while( li.hasNext() )
    {
      Light lg = (Light) li.next();
      // Generate distance, accounting for approximate map size
      float d = lg.pos.dist(posCentral) - (map.width * 0.5 * scalar);
      if(d < 1)  d = 1;  // Prevent singularities and inversions
      float brightness = lg.brightness * pow(1 / d, lg.falloffPower);
      if( (OPTIMAL_LIGHT_THRESHOLD < brightness)  ||  (lg.falloffPower == 0) )
      {
        // That is, the expected light yield is reasonable
        optimalLights.add(lg);
      }
    }
    
    
    // Process pixels
    lightBuffer.loadPixels();
    for(int i = 0;  i < lightBuffer.pixels.length;  i++)
    {
      // Derive position
      int x = i % lightBuffer.width;
      int y = floor(i / lightBuffer.width);
      int z = 0;
      // Offset position into real space
      PVector offset = new PVector(x, y);
      offset.rotate(ang);
      offset.mult(scalar);
      float ox = offset.x + pos.x;
      float oy = offset.y + pos.y;
      float oz = z + pos.z;
      // Declare position
      PVector pixPos = new PVector(x, y, z);
      PVector pixPosOffset = new PVector(ox, oy, oz);
      
      
      // Derive normal deviation
      color normCol = map.pixels[x + y * lightBuffer.width];    // This is a tiny bit faster than get(x,y)
      float normColR = map(red(normCol),  0, 255,  -1, 1);
      float normColG = map(green(normCol),  0, 255,  -1, 1);
      float normColB = map(blue(normCol),  0, 255,  -1, 1);
      PVector normalVector = new PVector(normColR, normColG, normColB);
      
      // Alter normal vector according to map rotation
      PVector normalRotVector = new PVector(normalVector.x, normalVector.y);
      normalRotVector.rotate(-ang);
      normalVector.set(normalRotVector.x, normalRotVector.y, normalVector.z);
      
      
      // Process lights
      
      // Setup colour buffers
      float r = 0;
      float g = 0;
      float b = 0;
      
      // Apply cumulative lighting
      for(int j = 0;  j < optimalLights.size();  j++)
      {
        // Get light
        Light light = (Light) optimalLights.get(j);
        light.setTarget(pixPosOffset.x, pixPosOffset.y, pixPosOffset.z);
        
        // Compute falloff
        float mag = light.getLightBrightness();
        
        // Compute angle
        PVector lightAngle = light.getLightVector();
        float angBetween = PVector.angleBetween(lightAngle, normalVector);
        float angAttenuation = map(angBetween,  0, PI,  -1, 1);
        
        // Constrain contribution to avoid negative light from normal maps
        // Light mag is not constrained, to permit intentional negative lights
        r += constrain(red(light.lightCol) * angAttenuation,  0, 255) * mag;
        g += constrain(green(light.lightCol) * angAttenuation,  0, 255) * mag;
        b += constrain(blue(light.lightCol) * angAttenuation,  0, 255) * mag;
      }
      
      // Set light
      lightBuffer.pixels[i] = color(r, g, b, alpha(normCol));
    }
    
    // Complete operations
    lightBuffer.updatePixels();
  }
  // render
  
  
  void regenerateLightMap()
  // Reset light map parameters to be compatible with normal map
  {
    // Create draw buffer
    lightBuffer = createGraphics(map.width, map.height, P2D);
    lightBuffer.beginDraw();
    lightBuffer.clear();
    lightBuffer.endDraw();
  }
  // regenerateLightMap
}
// NormalMap
