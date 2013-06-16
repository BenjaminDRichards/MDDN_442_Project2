class Particle
// A really simple particle that stores transform, age, and some unchanging momentum
{
  DAGTransform transform;
  PVector vel;
  float spin;
  float age;
  float ageMax;
  boolean pleaseRemove;
  
  Particle(DAGTransform transform, PVector vel, float spin, float ageMax)
  {
    this.transform = transform;
    this.vel = vel;
    this.spin = spin;
    age = 0;
    this.ageMax = ageMax;
    pleaseRemove = false;
  }
  
  
  public void run(float tick)
  {
    // Time management
    age += tick;
    if(ageMax <= age)  pleaseRemove = true;
    
    // Simulation
    transform.moveWorld(vel.x * tick, vel.y * tick, vel.z * tick);
    transform.rotate(spin * tick);
  }
  // run
  
  
  public void render(PGraphics pg)
  {
    // Placeholder
  }
  // render
}
// Particle




class ParticleSprite extends Particle
// A particle with a picture
{
  Sprite sprite;
  
  ParticleSprite(Sprite sprite, PVector vel, float spin, float ageMax)
  {
    super(sprite.transform, vel, spin, ageMax);
    
    this.sprite = sprite;
  }
  
  public void render(PGraphics pg)
  {
    sprite.render(pg);
  }
  // render
}
// ParticleSprite



class ParticleStreak extends Particle
// A particle that draws based on its movement
{
  float streakWidth;
  
  ParticleStreak(DAGTransform transform, PVector vel, float spin, float ageMax, float streakWidth)
  {
    super(transform, vel, spin, ageMax);
    
    this.streakWidth = streakWidth;
  }
  
  
  public void render(PGraphics pg)
  {
    PVector pos = transform.getWorldPosition();
    PVector oldPos = new PVector(pos.x - vel.x, pos.y - vel.y);
    pg.line(pos.x, pos.y, oldPos.x, oldPos.y);
  }
  // render
}
