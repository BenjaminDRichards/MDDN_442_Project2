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
  public static final int FADE_INOUT = 3;
  public static final int FADE_INOUT_SMOOTH = 4;
  
  
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
    fadeDiff = FADE_SMOOTH;
    fadeNorm = FADE_SMOOTH;
    fadeSpec = FADE_SMOOTH;
    fadeEmit = FADE_SMOOTH;
    fadeWarp = FADE_SMOOTH;
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
    float ageAlpha = 1.0 - age / ageMax;
    sprite.alphaDiff = ageAlpha;
    sprite.alphaNorm = ageAlpha;
    sprite.alphaSpec = ageAlpha;
    sprite.alphaEmit = ageAlpha;
    sprite.alphaWarp = ageAlpha;
    
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
    float ageAlpha = 1.0 - age / ageMax;
    switch(mode)
    {
      case FADE_LINEAR:
        return( ageAlpha );
      case FADE_SMOOTH:
        return( 3 * pow(ageAlpha, 2) - 2 * pow(ageAlpha, 3) );
      case FADE_INOUT:
        ageAlpha *= 2;
        if(1.0 < ageAlpha)  {  ageAlpha = 2 - ageAlpha;  }
        return( ageAlpha );
      case FADE_INOUT_SMOOTH:
        ageAlpha *= 2;
        if(1.0 < ageAlpha)  {  ageAlpha = 2 - ageAlpha;  }
        return( 3 * pow(ageAlpha, 2) - 2 * pow(ageAlpha, 3) );
      default:
        break;
    }
    return( ageAlpha );
  }
  // getAlpha
}
// Particle
