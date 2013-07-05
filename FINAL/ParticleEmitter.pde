class ParticleEmitter
// Stores and emits templated particles
// Templates must be stored with maximum positive spin, velocity, and ageMax
{
  DAGTransform transform;
  ArrayList templates;
  float emitRate;
  float emitLevel;
  
  ParticleEmitter(DAGTransform transform, Particle template, float emitRate)
  {
    this.transform = transform;
    
    templates = new ArrayList();
    if(template != null)
      addTemplate(template);
    
    this.emitRate = emitRate;
    emitLevel = 0;
  }
  
  
  public ArrayList run(float tick)
  {
    ArrayList outParticles = new ArrayList();
    emitLevel += emitRate * tick * transform.getLocalScale().x;  // This allows animation
    while(1.0 < emitLevel)
    {
      outParticles.add( getParticle() );
      emitLevel -= 1.0;
    }
    return( outParticles );
  }
  // run
  
  
  public Particle getParticle()
  // Get (a random) one of the templated particles, give it random velocity and lifespan
  {
    int index = floor( random( templates.size() ) );
    Particle template = (Particle) templates.get(index);
    
    // Create input objects
    // Transform
    PVector tpos = transform.getWorldPosition();  // Take it from the emitter
    DAGTransform dag = new DAGTransform(tpos.x, tpos.y, tpos.z,  random(TWO_PI),  1,1,1);
    // Sprite
    Sprite sprite = new Sprite(dag, null, template.sprite.coverageX, template.sprite.coverageY,
      template.sprite.centerX, template.sprite.centerY);
    // Tints
    sprite.tintDiff = template.sprite.tintDiff;
    sprite.tintNorm = template.sprite.tintNorm;
    sprite.tintSpec = template.sprite.tintSpec;
    sprite.tintEmit = template.sprite.tintEmit;
    sprite.tintWarp = template.sprite.tintWarp;
    // Master Tints
    sprite.masterTintDiff = template.sprite.masterTintDiff;
    sprite.masterTintNorm = template.sprite.masterTintNorm;
    sprite.masterTintSpec = template.sprite.masterTintSpec;
    sprite.masterTintEmit = template.sprite.masterTintEmit;
    sprite.masterTintWarp = template.sprite.masterTintWarp;
    // Sprite images
    sprite.setDiffuse( template.sprite.getDiffuse() );
    sprite.setNormal( template.sprite.getNormal() );
    sprite.setSpecular( template.sprite.getSpecular() );
    sprite.setEmissive( template.sprite.getEmissive() );
    sprite.setWarp( template.sprite.getWarp() );
    
    // Physics
    PVector velT = template.vel.get();
    float speedMax = velT.mag();
    float speed = pow(random(1.0), 2.0) * speedMax;
    PVector velN = PVector.random2D();
    velN.mult(speed);
    float spinN = random(-1, 1) * template.spin;
    // Age
    float ageMaxN = pow( random(1.0), 2.0 ) * template.ageMax;//random(template.ageMax);
    
    Particle p = new Particle(dag,  sprite,  velN, spinN, ageMaxN);
    p.age = 0.0;
    
    // Tweak parameters
    p.aimAlongMotion = template.aimAlongMotion;
    p.streak = template.streak;
    p.disperse = template.disperse;
    p.disperseSize = template.disperseSize;
    p.fadeDiff = template.fadeDiff;
    p.fadeNorm = template.fadeNorm;
    p.fadeSpec = template.fadeSpec;
    p.fadeEmit = template.fadeEmit;
    p.fadeWarp = template.fadeWarp;
    
    return( p );
  }
  // getParticle
  
  
  public void addTemplate(Particle template)
  {  templates.add(template);  }
  
}
// ParticleEmitter
