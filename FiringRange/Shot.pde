class Shot extends ParticleSprite
// Particle that carries an associated lightsource
{
  Light light;
  PVector lightOffset;
  
  // Impact assets
  PImage image_smoke = loadImage("smokePuff2.png");
  PImage image_smokeB = loadImage("smokePuff2B.png");
  PImage image_spark = loadImage("blast3.png");
  PImage image_chunk = loadImage("DebrisChunk.png");
  
  Shot(float px, float py, float pz, float vx, float vy, float vz, PImage img)
  {
    super(px, py, pz,  vx, vy, vz,  img);
    
    trail = true;
    
    lightOffset = new PVector(0, 0, 1);  // Evoke area light quality and avoid singularities
    
    light = new Light(px + lightOffset.x, py + lightOffset.y, pz + lightOffset.z,  0, 0, -1,  color(255,32,32), 512, 0, 2);
  }
  
  
  void run(float tick)
  // Extend method to support light updating
  {
    super.run(tick);
    
    light.pos.set(pos.x + lightOffset.x, pos.y + lightOffset.y, pos.z + lightOffset.z);
  }
  // run
  
  
  void setPos(PVector newPos)
  // Update position and light position immediately
  {
    pos.set(newPos.x, newPos.y, newPos.z);
    light.pos.set(newPos.x + lightOffset.x, newPos.y + lightOffset.y, newPos.z + lightOffset.z);
  }
  // setPos
  
  
  void doImpact(ParticleManager pm)
  // Visual effects for initial impact
  {
    // Smoke
    for(int j = 0;  j < 512;  j++)
    {
      // Create particle
      // Exact parameters might need tweaking
      float rSpd = 2;
      PVector rDir = new PVector(1,0);
      rDir.rotate(random(TWO_PI));
      rDir.mult(pow(random(1.0), 3) * rSpd);
      PImage pimg = (random(1.0) < 0.5)  ?  image_smoke  :  image_smokeB;
      ParticleSpriteDecay psd = new ParticleSpriteDecay(pos.x, pos.y, pos.z,
        rDir.x, rDir.y, random(10),
        pimg, color(255,16,192, 16), color(255,255,16) );
      psd.ageMax = random(180);
      psd.angVel.set(0, 0, random(-1,1));
      psd.die = true;
      psd.scalar = random(0.25, 0.75);
      pm.addDebris(psd);
    }
    // Sparks
    for(int j = 0;  j < 64;  j++)
    {
      float rSpd = 4;
      PVector rDir = new PVector(1,0);
      rDir.rotate(random(TWO_PI));
      rDir.mult(pow(random(1.0), 2) * rSpd);
      PImage pimg = image_spark;
      ParticleSpriteDecay psd = new ParticleSpriteDecay(pos.x, pos.y, pos.z,
        rDir.x, rDir.y, random(10),
        pimg, color(255,16,192, 255), color(255,255,16) );
      psd.ageMax = random(60);
      psd.trail = true;
      psd.die = true;
      psd.scalar = random(0.5, 1.0);
      pm.addDebris(psd);
    }
    // Debris chunks
    for(int j = 0;  j < 64;  j++)
    {
      float rSpd = 2;
      PVector rDir = new PVector(1,0);
      rDir.rotate(random(TWO_PI));
      rDir.mult(pow(random(1.0), 2) * rSpd);
      PImage pimg = image_chunk;
      ParticleSpriteDecay psd = new ParticleSpriteDecay(pos.x, pos.y, pos.z,
        rDir.x, rDir.y, random(10),
        pimg, color(255,16,192, 255), color(255,255,16) );
      psd.ageMax = random(180);
      psd.angVel.set(0, 0, random(-0.1,0.1));
      psd.die = true;
      psd.scalar = random(0.5);
      pm.addDebris(psd);
    }
  }
  // doImpact
  
}
// Shot
