class Particle
// A really simple particle that stores transform, age, and some unchanging momentum
{
  DAGTransform transform;
  Sprite sprite;
  PVector vel;
  float spin;
  boolean aimAlongMotion;
  boolean streak;
  boolean disperse;
  float disperseSize;
  float age;
  float ageMax;
  boolean pleaseRemove;
  
  int fadeDiff, fadeNorm, fadeSpec, fadeEmit, fadeWarp;
  
  public static final int FADE_LINEAR = 1;
  public static final int FADE_SMOOTH = 2;
  public static final int FADE_SQUARE = 3;
  public static final int FADE_CUBE = 4;
  public static final int FADE_INOUT = 5;
  public static final int FADE_INOUT_SMOOTH = 6;
  
  
  Particle(DAGTransform transform, Sprite sprite, PVector vel, float spin, float ageMax)
  {
    this.transform = transform;
    this.sprite = sprite;
    this.vel = vel;
    this.spin = spin;
    aimAlongMotion = false;
    streak = false;
    disperse = true;
    disperseSize = 4.0;
    age = 0;
    this.ageMax = ageMax;
    pleaseRemove = false;
    
    
    // Set fade modes
    fadeDiff = FADE_LINEAR;
    fadeNorm = FADE_LINEAR;
    fadeSpec = FADE_LINEAR;
    fadeEmit = FADE_LINEAR;
    fadeWarp = FADE_LINEAR;
  }
  
  
  public void run(float tick)
  {
    // Time management
    age += tick;
    if(ageMax <= age)  pleaseRemove = true;
    
    // Simulation
    transform.moveWorld(vel.x * tick, vel.y * tick, vel.z * tick);
    if(aimAlongMotion)
    {
      transform.setWorldRotation( atan2(vel.y, vel.x) + HALF_PI );  // Artistic up is 0, but not in screen coords
    }
    else
    {
      transform.rotate(spin * tick);
    }
    
    // Streak along motion
    if(streak)
    {
      transform.setLocalScale(1.0, 1.0 + vel.mag() / sprite.coverageY, 1.0);
    }
    
    // Age fading
    sprite.tintDiff = color( sprite.tintDiff, 255 * getAlpha(fadeDiff) );
    sprite.tintNorm = color( sprite.tintNorm, 255 * getAlpha(fadeNorm) );
    sprite.tintSpec = color( sprite.tintSpec, 255 * getAlpha(fadeSpec) );
    sprite.tintEmit = color( sprite.tintEmit, 255 * getAlpha(fadeEmit) );
    sprite.tintWarp = color( sprite.tintWarp, 255 * getAlpha(fadeWarp) );
    
    // Age dispersion
    if(disperse)
    {
      float newScale = 1.0 + disperseSize * (age / ageMax);
      transform.setLocalScale(newScale, newScale, newScale);
    }
  }
  // run
  
  
  public void render(PGraphics pg)
  {
    // Placeholder
  }
  // render
  
  
  private float getAlpha(int mode)
  {
    float ageAlpha = 1.0 - (age / ageMax);
    switch(mode)
    {
      case FADE_LINEAR:
        return( ageAlpha );
      case FADE_SMOOTH:
        return( 3.0 * pow(ageAlpha, 2.0) - 2.0 * pow(ageAlpha, 3.0) );
      case FADE_SQUARE:
        return( pow( ageAlpha, 2.0 ) );
      case FADE_CUBE:
        return( pow( ageAlpha, 3.0 ) );
      case FADE_INOUT:
        ageAlpha *= 2;
        if(1.0 < ageAlpha)  {  ageAlpha = 2 - ageAlpha;  }
        return( ageAlpha );
      case FADE_INOUT_SMOOTH:
        ageAlpha *= 2;
        if(1.0 < ageAlpha)  {  ageAlpha = 2 - ageAlpha;  }
        return( 3.0 * pow(ageAlpha, 2.0) - 2.0 * pow(ageAlpha, 3.0) );
      default:
        break;
    }
    return( ageAlpha );
  }
  // getAlpha
}
// Particle
