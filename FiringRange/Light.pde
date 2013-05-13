class Light
/*

Lights designed to interact with normal maps

Key to this lighting system is the Target.
The target is a sort of cursor, which must be set before the light can compute accurately.

*/
{
  // Transform data
  PVector pos, dir;
  
  // Light data
  color lightCol;
  float brightness;
  
  // Behavioural data
  int mode;    // What kind of light is this? 0 = point, 1 = directional
  int falloffPower;  // What power of decay does the light have? 2 is physically accurate.
  float spotArc, spotFringe;  // Spotlight parameters
  
  // Illuminated target data
  PVector targPos;
  
  Light(float px, float py, float pz, 
    float dx, float dy, float dz, 
    color lightCol, float brightness, int mode, int falloffPower)
  {
    pos = new PVector(px, py, pz);
    dir = new PVector(dx, dy, dz);
    this.lightCol = lightCol;
    this.brightness = brightness;
    this.mode = mode;
    this.falloffPower = falloffPower;
    spotArc = QUARTER_PI;
    spotFringe = QUARTER_PI / 4;
    targPos = new PVector(0,0,0);
  }
  
  
  void setTarget(float x, float y, float z)
  // Sets the coordinates for the entity/pixel being lit at this instant
  {
    targPos.set(x, y, z);
  }
  // setTarget
  
  
  PVector getLightVector()
  // Returns the vector that light will have on a plane perpendicular to the camera at these coordinates
  {
    switch(mode)
    {
      case(0):
      {
        // Point light method
        return PVector.sub(targPos, pos);
        // Note that light is applied to position, resulting in reversed vector
      }
      case(1):
      {
        // Directional light method
        return dir;
      }
      case(2):
      {
        // Spotlight method
        // Spotlights are really just point lights with limited sweep
        return PVector.sub(targPos, pos);
      }
    }
    
    // Default response
    return(new PVector(0,0,-1));
  }
  // getLightVector
  
  
  float getLightBrightness()
  // Returns the computed fallen-off light magnitude
  {
    // Derive distance for all modes
    float dist = PVector.dist(pos, targPos);
    
    switch(mode)
    {
      case(0):
      {
        // Point light method
        // Derive brightness
        return( brightness * pow(1 / dist, falloffPower) );
      }
      case(1):
      {
        // Directional light method
        // This is normally used with falloff 0, but might as well include options
        // Derive brightness
        return( brightness * pow(1 / dist, falloffPower) );
      }
      case(2):
      {
        // Spotlight method
        // More complex version of a point light
        float deviation = PVector.angleBetween(dir, getLightVector());
        if(0 < spotFringe)
        {
          // Falloff is necessary
          // Normalise and invert
          deviation = map(deviation, spotArc, spotArc + spotFringe,  1, 0);
          // Keep it between full and completely fallen off
          deviation = constrain(deviation, 0, 1);
        }
        else
        {
          // No falloff
          if(spotArc <= deviation)  deviation = 0;
          else  deviation = 1;
        }
        // Compute brightness
        float mag = brightness * pow(1 / dist, falloffPower);
        return(mag * deviation);
      }
    }
    
    // Default response
    return(0);
  }
  // getLightBrightness
  
}
// Light
