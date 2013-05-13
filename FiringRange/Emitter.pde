class Emitter extends Shot
// Positional entity that creates particles
// This extends Shot, which has all the stuff it needs, but isn't really a Shot
{
  ParticleManager pManager;
  
  // Emission dynamics
  PVector aim;          // Direction, magnitude irrelevant
  float aimJitter;      // Directional jitter, ratio to aim is relevant
  float emitVel;        // Base velocity
  float emitVelJitter;  // Allowable velocity randomness
  
  // Emission rates
  float emitRequests;   // How many particles need to be rendered
  float emitRate;       // How many particles per tick
  
  // Style emitter
  color projectileTint;
  
  
  Emitter(float px, float py, float pz, float vx, float vy, float vz, PImage img, ParticleManager pManager)
  {
    super(px, py, pz,  vx, vy, vz,  img);
    
    this.pManager = pManager;
    
    // Default emission data
    aim = new PVector(1,1,-1);
    aimJitter = 0.0;
    emitVel = 16;
    emitVelJitter = 0.0;
    
    emitRequests = 0;
    emitRate = 1;
    
    // Turn off the light by default
    light.brightness = 0;
    lightOffset.set(0,0, 32);  // Modify lighting position
    
    projectileTint = color(255);
  }
  
  
  void run(float tick)
  // Extends template to do particle emission
  {
    super.run(tick);
    
    emitRequests += emitRate * tick;
    doEmission();
  }
  // run
  
  
  void doEmission()
  // Emit some particles
  {
    while(1 <= emitRequests)
    {
      // Get a particle
      Particle p = createParticle();
      
      // Style the particle velocity
      PVector aimRand = PVector.random3D();
      aimRand.mult(aimJitter);
      p.vel.set(aim.x + aimRand.x, aim.y + aimRand.y, aim.z + aimRand.z);
      p.vel.setMag( emitVel + random(-emitVelJitter, emitVelJitter) );
      
      // Put the particle into the program flow
      registerWithManager(p);
      
      // Register request completion
      emitRequests -= 1;
    }
  }
  // doEmission
  
  
  Particle createParticle()
  // Generate a particle
  // Intended to be overridden by emitter types
  {
    return( new Particle(pos.x, pos.y, pos.z,  0,0,0) );
  }
  // createParticle
  
  
  void registerWithManager(Particle p)
  // Put the particle in the correct category
  // Intended to be overridden by emitter types
  {
    pManager.addDebris(p);
  }
  // registerWithManager
}
// Emitter



class Emitter_Shooter extends Emitter
// A basic shooting turret
{
  PImage imgProjectile = loadImage("blast3.png");
  float emitMaster;
  float chanceStart;
  float chanceStop;
  
  Emitter_Shooter(float px, float py, float pz, float vx, float vy, float vz, PImage img, ParticleManager pManager)
  {
    super(px, py, pz,  vx, vy, vz,  img, pManager);
    
    aimJitter = 0.2;
    emitVel = 8;
    emitRate = 0.2;
    emitMaster = emitRate;
    chanceStart = 0.2;
    chanceStop = 0.3;
    
    projectileTint = color(255,16,192);
  }
  
  
  void run(float tick)
  // Extend default run
  {
    super.run(tick);
    
    // Turn off and on at random
    float chance = random(1);
    if(emitRate != emitMaster)
    {
      // Emission is not happening
      if(chance <= chanceStart)
      {
        // Start emitting
        emitRate = emitMaster;
      }
    }
    else
    {
      // Emission is happening
      if(chance <= chanceStop)
      {
        // Stop emitting
        emitRate = 0;
      }
    }
  }
  // run
  
  
  Particle createParticle()
  // Overrides default method
  {
    Shot s = new Shot(pos.x, pos.y, pos.z,  0,0,0,  imgProjectile);
    // Position is set above to prevent teleportation errors
    // Position is set below to synch with lighting
    s.setPos(pos);
    s.spriteTint = projectileTint;
    s.light.lightCol = projectileTint;
    return(s);
  }
  // createParticle
  
  
  void registerWithManager(Particle p)
  // Overrides default method
  {
    Shot s = (Shot) p;
    
    pManager.addShot(s);
  }
  // registerWithManager
}
// Emitter_Shooter


class Emitter_Shooter_Green extends Emitter_Shooter
// This one shoots green stuff, not purple
{
  Emitter_Shooter_Green(float px, float py, float pz, float vx, float vy, float vz, PImage img, ParticleManager pManager)
  {
    super(px, py, pz,  vx, vy, vz,  img, pManager);
    
    projectileTint = color(64,255,128);
  }
}
// Emitter_Shooter_Green



class Emitter_Impact extends Emitter
// Emitter that releases a trail of burning debris from weapon impacts
{
  PImage imgPuff = loadImage("smokePuff2.png");
  PImage imgPuffB = loadImage("smokePuff2B.png");
  PImage image_chunk = loadImage("DebrisChunk.png");
  float emitDecayMax;
  float emitRateOrigin;
  float lightMaxBrightness;
  
  Emitter_Impact(float px, float py, float pz, float vx, float vy, float vz, PImage img, ParticleManager pManager)
  {
    super(px, py, pz,  vx, vy, vz,  img, pManager);
    
    emitRate = 3;
    aim.set(0,0,1);
    aimJitter = 1;
    emitVel = 0.2;
    emitVelJitter = 1;
    
    emitDecayMax = 0.003;
    emitRateOrigin = emitRate;
    lightMaxBrightness = 500;
    
    light.lightCol = color(255,16,192);
  }
  
  
  void run(float tick)
  // Extend template
  {
    super.run(tick);
    
    // Decay emission rate
    emitRate -= random(emitDecayMax) * tick;
    if(emitRate <= 0)  pleaseRemove = true;
    
    // Decay light
    light.brightness = lightMaxBrightness * emitRate / emitRateOrigin;
  }
  // run
  
  
  Particle createParticle()
  // Overrides default method
  {
    // Select type
    // Default parameters
    PImage pimg = (random(1.0) < 0.5)  ?  imgPuff  :  imgPuffB;  // Left or right handed poof?
    color col1 = color(255,16,192, 16);
    color col2 = color(255,255,16);
    float conserve = 0.97;
    float minScale = 0.25;
    float maxScale = 0.75;
    // Debris parameters
    if(random(1.0) < 0.01)
    {
      pimg = image_chunk;
      col1 = color(255,16,192,255);
      conserve = 1.0;
      minScale = 0.0;
      maxScale = 0.5;
    }
    
    ParticleSpriteDecay p = new ParticleSpriteDecay(pos.x, pos.y, pos.z,  0,0,0,
      pimg,  col1, col2 );
    p.ageMax = random(180);
    p.die = true;
    p.angVel.set(0, 0, random(-0.1,0.1));
    p.inertia = conserve;
    p.inertiaAng = conserve;
    p.scalar = random(minScale, maxScale);
    return p;
  }
  // createParticle
}
// Emitter_Impact



class Emitter_Drive extends Emitter
// A drive emitter
{
  PImage image_exhaust = loadImage("smokePuff1.png");
  color exhaustParticleCol;
  
  
  Emitter_Drive(float px, float py, float pz, float vx, float vy, float vz, PImage img, ParticleManager pManager)
  {
    super(px, py, pz,  vx, vy, vz,  img, pManager);
    
    exhaustParticleCol = color(64, 255, 128, 16);
    
    // Style drive illumination
    light.brightness = 1024;
    light.lightCol = exhaustParticleCol;
    
    // Style emission
    aim.set(0,0,1);
    aimJitter = 1;
    emitVel = 0.5;
    emitRate = 0.5;
  }
  
  Particle createParticle()
  // Overrides default method
  {
    ParticleSpriteDecay p = new ParticleSpriteDecay(pos.x, pos.y, pos.z,  0,0,0,
      image_exhaust,  exhaustParticleCol, exhaustParticleCol );
    p.ageMax = random(180);
    p.die = true;
    p.angVel.set(0, 0, random(-0.01,0.01));
    p.inertia = 0.97;
    p.inertiaAng = 0.99;
    p.scalar = 2.0;
    return p;
  }
  // createParticle
}
// Emitter_Drive
