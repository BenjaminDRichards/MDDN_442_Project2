import java.util.*;


class Ship
{
  // Structural data
  private DAGTransform root;      // Root transform
  private ArrayList sprites;      // Sprites for rendering
  private ArrayList slaves;       // Sub-ships such as turrets
  private ArrayList lights;       // Lights attached to ship structure
  
  // Navigational data
  private int navMode;
  private DAGTransform target;
  private PVector externalVector;       // Optional external target feed
  private ShipManager shipManager;      // Used in avoidance navigation routines
  private float rateVel, rateTurn;      // Momentum figures
  private float maxVel, maxTurn;
  private float radius, destinationRadius;
  private float thrust, drag, brake;
  private float turnThrust, turnDrag, turnBrake;
  private boolean wrap;
  private PVector wrapX, wrapY;         // Dimensional bounds: low/high/range parameters
  
  public static final int NAV_MODE_MOUSE = 1;
  public static final int NAV_MODE_AVOID = 2;
  public static final int NAV_MODE_HOMING = 3;
  public static final int NAV_MODE_TURRET = 4;
  public static final int NAV_MODE_BULLET = 5;
  public static final int NAV_MODE_EXTERNAL = 6;
  
  // Animation data
  ArrayList animTurnLeft, animTurnRight, animThrust, anim;
  ArrayList particles, emitters;
  
  // Destructural data
  private ArrayList breakpoints;  // Children of root that might break away during an explosion
  private ArrayList fragments;    // Pieces that break away from root
  private boolean exploding;
  public boolean pleaseRemove;
  private float explodeTimer, explodeTimerInterval;
  private float dismemberTimer, dismemberTimerInterval;
  color colExplosion;
  int explosionParticles;
  ArrayList explosionTemplates;
  
  // Military data
  boolean invulnerable;
  boolean targetable;
  int team;
  float age, ageMax;
  PVector turretRange;    // Low angle/High angle/Maximum engagement range
  float turretAcquisitionArc;  // How wide an angle it will fire from
  float reload, reloadTime;
  boolean shooting;
  float firingTime, firingTimeMax;
  int munitionType;
  color teamCol;
  
  // Stealth data
  float excitement;  // This must be extracted from slave ships
  float excitementDecay;
  boolean communicateExcitement;
  boolean cloakOnInactive;
  boolean cloaked;
  float cloakActivation;
  float cloakActivationSpeed;
  
  // Munition data
  public static final int MUNITION_BULLET_A = 0;
  public static final int MUNITION_MISSILE_A = 1;
  
  
  Ship(PVector pos, PVector targetPos, int navMode, ShipManager shipManager, int team)
  {
    root = new DAGTransform(pos.x, pos.y, pos.z,  0,  1,1,1);
    target = new DAGTransform(targetPos.x, targetPos.y, targetPos.z,  0,  1,1,1);
    this.shipManager = shipManager;
    
    // Assets and animation
    sprites = new ArrayList();
    slaves = new ArrayList();
    lights = new ArrayList();
    animTurnLeft = new ArrayList();
    animTurnRight = new ArrayList();
    animThrust = new ArrayList();
    anim = new ArrayList();
    particles = new ArrayList();
    emitters = new ArrayList();
    
    // Navigation parameters
    this.navMode = navMode;
    rateVel = 0;
    rateTurn = 0;
    maxVel = 0.1;
    maxTurn = 0.02;
    radius = 5;
    destinationRadius = 5;
    thrust = 0.001;
    drag = 0.995;
    brake = thrust;
    turnThrust = 0.0005;
    turnDrag = 0.98;
    turnBrake = turnThrust;
    wrap = true;
    float margin = 1.15;
    float xDimension = 100.0 * margin * width / height;
    float yDimension = 100.0 * margin;
    wrapX = new PVector(-0.5 * xDimension, 0.5 * xDimension, xDimension);  // Low bound, high bound, range
    wrapY = new PVector(-0.5 * yDimension + 50, 0.5 * yDimension + 50, yDimension);  // Low bound, high bound, range
    
    // Destruction data
    breakpoints = new ArrayList();
    fragments = new ArrayList();
    exploding = false;
    pleaseRemove = false;
    explodeTimer = 0;
    explodeTimerInterval = 60;
    dismemberTimer = 0;
    dismemberTimerInterval = 30;
    colExplosion = color(127, 255, 192, 255);
    explosionParticles = 512;
    explosionTemplates = new ArrayList();
    setupExplosionTemplatesA();
    
    // Military data
    invulnerable = false;
    targetable = true;
    this.team = team;
    age = 0;
    ageMax = 180;  // This is only used for missiles
    turretRange = new PVector(-HALF_PI, HALF_PI, 30);
    turretAcquisitionArc = 0.2;
    reload = 0;
    reloadTime = 180;
    shooting = false;
    firingTime = 0;
    firingTimeMax = 20;
    munitionType = MUNITION_BULLET_A;
    teamCol = color(255,255,255);
    
    // Stealth data
    excitement = 0;  // This must be extracted from slave ships
    excitementDecay = 0.004;
    communicateExcitement = false;
    cloakOnInactive = false;
    cloaked = false;        // Communicate to slave ships
    cloakActivation = 0.0;  // Communicate to slave ships
    cloakActivationSpeed = 0.004;
    
    // Position ship facing target
    snapToFaceTarget();
  }
  
  
  public void run(float tick)
  // Perform animation/simulation/navigation
  {
    // Handle target
    // Navigate towards target
    doNavigation(tick);
    
    // Secondary animations
    doAnimation(tick);
    
    // Animate particles
    doParticles(tick);
    
    // Run emitters
    doEmitters(tick);
    
    // Manage excitement
    if( 0.01 < abs(rateVel)  ||  0.001 < abs(rateTurn) )
    {
      // Elevate excitement
      excitement = 1.0;
    }
    excitement = max(excitement - excitementDecay * tick, 0.0);
    
    // Operate cloaking device
    doCloaking(tick);
    
    // Check explosions
    if(exploding)
      doExploding(tick);
    
    // Do aging and time management
    age += tick;
    if(!shooting)
    {      reload += tick;    }
    else
    {
      firingTime += tick;
      if(firingTimeMax < firingTime)
      {        shooting = false;      }
    }
    
    // Do slaves
    Iterator i = slaves.iterator();
    while( i.hasNext() )
    {
      Ship slave = (Ship) i.next();
      // Run slave
      slave.run(tick);
      // Transfer excitement
      if(communicateExcitement)
      {
        excitement = max(excitement, slave.excitement);
        slave.excitement = excitement;
      }
      slave.cloaked = cloaked;
      slave.cloakActivation = cloakActivation;
    }
  }
  // run
  
  
  public void render(RenderManager renderManager)
  {
    Iterator i = sprites.iterator();
    while( i.hasNext() )
    {
      Sprite s = (Sprite) i.next();
      renderManager.addSprite(s);
    }
    
    // Do lights
    Iterator iL = lights.iterator();
    while( iL.hasNext() )
    {
      Light light = (Light) iL.next();
      renderManager.addLight(light);
    }
    
    // Do slaves
    Iterator j = slaves.iterator();
    while( j.hasNext() )
    {
      Ship slave = (Ship) j.next();
      slave.render(renderManager);
    }
    
    // Do particles
    Iterator k = particles.iterator();
    while( k.hasNext() )
    {
      Particle p = (Particle) k.next();
      renderManager.addSprite(p.sprite);
    }
  }
  // render
  
  
  public void render(PGraphics pg)
  {
    Iterator i = sprites.iterator();
    while( i.hasNext() )
    {
      Sprite s = (Sprite) i.next();
      s.render(pg);
    }
    
    // Particles
    pg.pushStyle();
    pg.stroke(255);
    pg.strokeWeight(0.1);
    i = particles.iterator();
    while( i.hasNext() )
    {
      Particle p = (Particle) i.next();
      p.render(pg);
    }
    pg.popStyle();
    
    // Do slaves
    Iterator j = slaves.iterator();
    while( j.hasNext() )
    {
      Ship slave = (Ship) j.next();
      slave.render(pg);
    }
  }
  // render
  
  public void render()
  {  render(g);  }
  
  
  
  private void doNavigation(float tick)
  // Handle navigation target and progression towards same
  {
    // Handle target
    doNavTargeting();
    
    
    // Movement and steering
    // Get data
    PVector rpos = root.getWorldPosition();
    PVector tpos = target.getWorldPosition();
    float rr = root.getWorldRotation();
    // Normalise rotation data
    root.normalizeRotations();
    target.normalizeRotations();
    
    // When outside region, steer towards it
    if( destinationRadius < rpos.dist( tpos ) )
    {
      // Turn towards target
      PVector separation = PVector.sub(tpos, rpos);
      float sepAngle = separation.heading();
      // Bring to the same side as the heading, to avoid turning the wrong way
      if(PI < sepAngle - rr)  sepAngle -= TWO_PI;
      if(PI < rr - sepAngle)  sepAngle += TWO_PI;
      // Turn towards the heading
      if(rr < sepAngle)
      {
        // Turn left
        rateTurn += turnThrust * tick;
      }
      if(sepAngle < rr)
      {
        // Turn right
        rateTurn -= turnThrust * tick;
      }
      
      // Accelerate towards target
      rateVel += thrust * tick;
    }
    
    // When inside region, slow down and match heading
    else
    {
      rateVel  = max( rateVel - brake * tick,  0.0 );
    }
    
    // Apply navigational physics
    rateTurn = constrain(rateTurn, -maxTurn * tick, maxTurn * tick) * pow(turnDrag, tick);
    root.rotate(rateTurn);
    rateVel = constrain(rateVel, -maxVel * tick, maxVel * tick) * pow(drag, tick);
    PVector thrustVector = PVector.fromAngle( root.getWorldRotation() );
    thrustVector.mult(rateVel);
    root.moveLocal(thrustVector.x, thrustVector.y, thrustVector.z);
    
    // Wrap around activity area
    if(wrap)
    {
      rpos = root.getWorldPosition();
      if(rpos.x < wrapX.x)  root.moveWorld(wrapX.z, 0, 0);
      else if(wrapX.y < rpos.x)  root.moveWorld(-wrapX.z, 0, 0);
      if(rpos.y < wrapY.x)  root.moveWorld(0, wrapY.z, 0);
      else if(wrapY.y < rpos.y)  root.moveWorld(0, -wrapY.z, 0);
    }
  }
  // doNavigation
  
  
  private void doNavTargeting()
  // Figure out where the ship is going
  {
    switch(navMode)
    {
      case NAV_MODE_MOUSE:
        target.setWorldPosition(screenMouseX(), screenMouseY(), 0);
        break;
      case NAV_MODE_AVOID:
        doNavTargetingAvoid();
        break;
      case NAV_MODE_TURRET:
        doNavTargetingTurret();
        break;
      case NAV_MODE_HOMING:
        doNavTargetingHoming();
        break;
      case NAV_MODE_BULLET:
        doNavTargetingBullet();
        break;
      case NAV_MODE_EXTERNAL:
        target.setWorldPosition(externalVector.x, externalVector.y, 0);
        break;
      default:
        break;
    }
  }
  // doNavTargeting
  
  
  private void doNavTargetingAvoid()
  // Behaviour that avoids other ships in the manager
  {
    // Place the camera comfortably in front of the ship
    target.snapTo(root);
    target.setParent(root);
    target.moveLocal(radius * 4.0, 0, 0);
    target.setParentToWorld();
    // Introduce some wiggle
    /*
    float r = 1.0;
    target.moveLocal( random(-r,r), random(-r,r), random(-r,r) );
    */
    PVector r = PVector.random2D();
    r.mult(1.0);
    target.moveLocal(r.x, r.y, 0.0);
    // Look for nearby obstacles
    float radiusMult = 2.0;
    float detectRadius = radius * radiusMult;
    Ship ship = shipManager.getNearestShipTo( target.getWorldPosition() );
    if(ship != null)
    {
      PVector vecBetween = PVector.sub( root.getWorldPosition(),  ship.getRoot().getWorldPosition() );
      float otherDetectRadius = ship.radius * radiusMult;
      if( vecBetween.mag() < detectRadius + otherDetectRadius)
      {
        target.moveWorld(vecBetween.x, vecBetween.y, vecBetween.z);
      }
    }
  }
  // doNavTargetingAvoid
  
  
  private void doNavTargetingTurret()
  // A turret that aims towards hostile ships
  {
    if(cloaked)  return;  // Everybody knows that cloaks draw power from the weapons array
    
    // Select an enemy target within a certain arc
    ArrayList enemies = shipManager.getEnemiesOf(team);
    PVector rpos = root.getWorldPosition();
    float rang = root.getWorldRotation();
    Ship candidate = null;
    float candidateDeviation = 0;
    
    Iterator i = enemies.iterator();
    while( i.hasNext() )
    {
      Ship enemy = (Ship) i.next();
      PVector enemyPos = enemy.getRoot().getWorldPosition();
      PVector vecToEnemy = PVector.sub(enemyPos, rpos);
      float angToEnemy = vecToEnemy.heading();
      float angDiff = angToEnemy - rang;
      float rangeLow = turretRange.x + root.getLocalRotation();
      float rangeHigh = turretRange.y + root.getLocalRotation();
      //if( turretRange.x < angToEnemy  &&  angToEnemy < turretRange.y  &&  vecToEnemy.mag() < turretRange.z )
      //if( rangeLow < angToEnemy  &&  angToEnemy < rangeHigh  &&  vecToEnemy.mag() < turretRange.z )
      if( vecToEnemy.mag() < turretRange.z )
      {
        // Valid target
        if( candidate == null  ||  abs(angDiff) < candidateDeviation )
        {
          candidate = enemy;
          candidateDeviation = abs(angDiff);
        }
      }
    }
    if(candidate != null)
    {
      // Target that vessel
      target.snapTo( candidate.getRoot() );
    }
    else
    {
      // Revert to original orientation
      target.snapTo( root );
      PVector reAim = PVector.fromAngle( root.getWorldRotation() - root.getLocalRotation() );
      target.moveWorld(reAim.x, reAim.y);
    }
    // Fire at valid targets
    if(candidateDeviation < turretAcquisitionArc  &&  candidate != null)
    {
      fireWeapon();
    }
  }
  // doNavTargetingTurret
  
  
  private void doNavTargetingHoming()
  // Home in on the nearest enemy and explode
  {
    // Find nearest enemy
    Ship enemy = shipManager.getNearestEnemyTo( root.getWorldPosition(),  team );
    if(enemy != null)
    {
      target.snapTo( enemy.getRoot() );
      // Check for proximity
      if( enemy.getRoot().getWorldPosition().dist( root.getWorldPosition() ) < radius )
      {
        // Kill yourself
        startExploding();
        // Kill the enemy too
        enemy.takeHit();
      }
    }
    // Time out
    if(ageMax < age)
    {
     startExploding();
    }
  }
  // doNavTargetingHoming
  
  
  private void doNavTargetingBullet()
  // Fly unaltered until you hit an enemy
  {
    Iterator i = shipManager.ships.iterator();
    while( i.hasNext() )
    {
      Ship enemy = (Ship) i.next();
      if(enemy.team == team)  continue;  // Don't hit friendlies
      if(enemy.getRoot().getWorldPosition().dist( root.getWorldPosition() ) < enemy.radius + radius)
      {
        // That is, the two are close enough to collide
        // Kill yourself
        startExploding();
        // Kill the enemy too
        enemy.takeHit();
        // Slow down, you might hit something else
        rateVel = 0;
        break;
      }
    }
    
    // Time out
    if(ageMax < age)
    {
     startExploding();
    }
  }
  // doNavTargetingBullet
  
  
  private void doAnimation(float tick)
  // Run Animators for secondary animation based on nav simulation
  {
    // Generic animations
    Iterator it_anim = anim.iterator();
    while( it_anim.hasNext() )
    {
      Animator a = (Animator) it_anim.next();
      a.run(tick);
      if(a.pleaseRemove)  it_anim.remove();
    }
    
    // Compute rates of change
    float roc_turnLeft = max( -rateTurn / maxTurn,  0.0 );
    float roc_turnRight = max( rateTurn / maxTurn,  0.0 );
    float roc_thrust = max( rateVel / maxVel,  0.0 );
    
    // Apply rates of change to animation sliders
    // Turn left
    Iterator it_turnLeft = animTurnLeft.iterator();
    while( it_turnLeft.hasNext() )
    {
      Animator a = (Animator) it_turnLeft.next();
      a.setSlider(roc_turnLeft);
      a.run(tick);
    }
    // Turn right
    Iterator it_turnRight = animTurnRight.iterator();
    while( it_turnRight.hasNext() )
    {
      Animator a = (Animator) it_turnRight.next();
      a.setSlider(roc_turnRight);
      a.run(tick);
    }
    // Thrust ahead
    Iterator it_thrust = animThrust.iterator();
    while( it_thrust.hasNext() )
    {
      Animator a = (Animator) it_thrust.next();
      a.setSlider(roc_thrust);
      a.run(tick);
    }
  }
  // doAnimation
  
  
  private void doParticles(float tick)
  {
    Iterator i = particles.iterator();
    while( i.hasNext() )
    {
      Particle p = (Particle) i.next();
      p.run(tick);
      if(p.pleaseRemove)  i.remove();
    }
  }
  // doParticles
  
  
  private void doEmitters(float tick)
  {
    Iterator i = emitters.iterator();
    while( i.hasNext() )
    {
      ParticleEmitter pe = (ParticleEmitter) i.next();
      ArrayList pList = pe.run(tick);
      if( 0 < pList.size() )  particles.addAll(pList);
    }
  }
  // doEmitters
  
  
  private void doCloaking(float tick)
  {
    if(!cloakOnInactive)  return;
    
    if(cloaked)
    {
      if(0 < excitement)
      {
        // Start reactivation
        cloaked = false;
      }
      else
      {
        // Power up cloak
        cloakActivation = min(cloakActivation + cloakActivationSpeed, 1.0);
      }
    }
    else
    {
      if(excitement <= 0)
      {
        // Start cloaking
        cloaked = true;
      }
      else
      {
        // Power down cloak
        cloakActivation = max(cloakActivation - cloakActivationSpeed, 0.0);
      }
    }
    
    // Manage warp profiles
    // This will override any other warp effects on sprites
    Iterator i = sprites.iterator();
    while( i.hasNext() )
    {
      float aleph = 1 - cloakActivation;
      float baseAlpha = 3 * pow(aleph, 2) - 2 * pow(aleph, 3);
      float warpBase = aleph < 0.5  ?  aleph * 2  :  2 - aleph * 2;
      float warpAlpha = 3 * pow(warpBase, 2) - 2 * pow(warpBase, 3);
      
      // Prevent total fade
      baseAlpha = max(baseAlpha, cloakActivation / 64.0);
      warpAlpha = max(warpAlpha, cloakActivation / 64.0);
      
      // Do something absurd to the warp normal tint
      // This might not currently work, due to tint-disabled warp rendering
      float warpPhase = aleph * TWO_PI * 4.0;
      PVector wd = new PVector( 1.0 - sin(warpPhase ),
        1.0 - sin(warpPhase * TWO_PI / 3.0), 1.0 - sin(warpPhase * TWO_PI * 2.0 / 3.0) );
      wd.mult( 127 * (1.0 - warpAlpha) );
      wd.add( new PVector(255,255,255) );
      
      Sprite s = (Sprite) i.next();
      s.tintDiff = color(teamCol, 255 * baseAlpha);
      s.tintNorm = color(255, 255 * baseAlpha);
      s.tintSpec = color(teamCol, 255 * baseAlpha);
      s.tintEmit = color(255, 255 * baseAlpha);
      s.tintWarp = color(wd.x,wd.y,wd.z, 255 * warpAlpha);  // It turns on, then off
    }
  }
  // doCloaking
  
  
  public void fireWeapon()
  // Perform aggressive emission
  {
    if(reloadTime < reload  &&  cloakActivation == 0)
    {
      // Weapon is primed
      shooting = true;
      reload = 0;
      firingTime = 0;
      // Create and emit munition
      Ship munition = null;
      PVector pos = root.getWorldPosition().get();
      PVector targetPos = target.getWorldPosition().get();
      switch(munitionType)
      {
        case MUNITION_BULLET_A:
          munition = shipManager.makeShip(pos, targetPos, ShipManager.MODEL_BULLET_A, team);
          break;
        case MUNITION_MISSILE_A:
          munition = shipManager.makeShip(pos, targetPos, ShipManager.MODEL_MISSILE_A, team);
          break;
        default:
          break;
      }
      
      // Elevate excitement
      excitement = 1.0;
    }
  }
  // fireWeapon
  
  
  public void takeHit()
  // What to do if you get hit
  {
    if(!invulnerable)
    {
      startExploding();
    }
  }
  // takeHit
  
  
  public void startExploding()
  // Initiate a sequence of events that eventually destroy the ship
  {
    if(!exploding)
    {
      // Set the ship on its course: disable steering
      thrust = 0;
      brake = 0;
      turnThrust = 0;
      wrap = false;      // It's no good seeing exploding ships appear unexpectedly
      animTurnLeft.clear();
      animTurnRight.clear();
      animThrust.clear();
      anim.clear();
      lights.clear();
      emitters.clear();  // Or the dead ship will be kept alive by emissions...
      
      // Enable explosion systems
      exploding = true;
    }
  }
  // startExploding
  
  
  private void doExploding(float tick)
  // Handle explosive dismemberment
  {
    // Do component elimination
    explodeTimer += random(tick);
    while( explodeTimerInterval <= explodeTimer )
    {
      // Reset timer
      explodeTimer -= explodeTimerInterval;
      
      // If there are no more sprites and the particles have run out, request removal
      if( sprites.size() <= 0 )
      {
        if( particles.size() == 0 )
        {
          pleaseRemove = true;
        }
        return;
      }
      
      // Select random sprite
      int index = floor( random( sprites.size() ) );
      Sprite s = (Sprite) sprites.get(index);
      
      // Make an explosion
      makeExplosion( s.transform.getWorldPosition() );
      
      // Remove that sprite
      sprites.remove(index);
    }
    
    // If there's anything left to explode:
    
    // Do dismemberment
    dismemberTimer += random(tick);
    while( dismemberTimerInterval <= dismemberTimer )
    {
      // Reset timer
      dismemberTimer -= dismemberTimerInterval;
      // Select a breakpoint
      if(breakpoints.size() < 1)  continue;  // There are no breakpoints so don't bother
      int index = floor( random( breakpoints.size() ) );
      DAGTransform breakpoint = (DAGTransform) breakpoints.get(index);
      // If it's not already broken...
      if( breakpoint.isChildOf(root) )
      {
        breakOff(breakpoint);
      }
    }
    
  }
  // doExploding
  
  
  private void breakOff(DAGTransform breakpoint)
  {
    // Break it off
      breakpoint.setParentToWorld();
      fragments.add(breakpoint);
      
      // Push it and the main mass apart
      // Get separation vector and tumble
      PVector sep = PVector.sub(breakpoint.getWorldPosition(), root.getWorldPosition());
      PVector randDir = PVector.random3D();
      randDir.mult( sep.mag() );
      sep.add(randDir);
      float tumble = random(-0.04, 0.04);
      // Normalize and multiply by an acceptable velocity
      sep.normalize();
      sep.mult( random(0.02) );
      // Create animation
      PVector fragmentVel = new PVector(sep.x, sep.y, sep.z);
      PVector rootVel = PVector.fromAngle( root.getWorldRotation() );
      rootVel.mult(rateVel);
      fragmentVel.add(rootVel);
      breakpoint.useWorldSpace = true;
      breakpoint.usePX = true;  breakpoint.usePY = true;  breakpoint.usePZ = true;  breakpoint.useR = true;
      
      DAGTransform key1 = new DAGTransform(0,0,0, 0, 1,1,1);
      key1.snapTo(breakpoint);
      
      DAGTransform key2 = new DAGTransform(0,0,0, 0, 1,1,1);
      key2.snapTo(breakpoint);
      key2.rotate(tumble);
      key2.moveWorld(fragmentVel.x, fragmentVel.y, fragmentVel.z);
      
      Animator a = breakpoint.makeAnimator(key1, key2);
      a.setType(Animator.ANIM_LINEAR);
      anim.add(a);
      
      // Do an explosion at the site
      makeExplosion( breakpoint.getWorldPosition() );
      
      // Accelerate dismemberment
      dismemberTimerInterval *= 0.8;
  }
  // breakOff
  
  
  private void makeExplosion(PVector pos)
  // Emit some particles at position pos and flash with light
  {
    // Create particles
    int pop = int(random(0.5, 1.0) * explosionParticles);
    DAGTransform dagPE = new DAGTransform(pos.x, pos.y, pos.z,  0,  1,1,1);
    ParticleEmitter pe = new ParticleEmitter(dagPE, null, 0);
    Iterator iPE = explosionTemplates.iterator();
    while( iPE.hasNext() )
    {
      Particle p = (Particle) iPE.next();
      pe.addTemplate(p);
    }
    for(int i = 0;  i < pop;  i++)
    {
      particles.add( pe.getParticle() );
    }
    
    // Create shockwave
    DAGTransform dagShock = new DAGTransform(pos.x, pos.y, pos.z, 0, 1,1,1);
    Sprite sShock = new Sprite(dagShock, null, 2,2, -0.5,-0.5);
    sShock.setWarp(fx_shockwave);
    Particle pShock = new Particle(dagShock, sShock, new PVector(0,0,0), 0, 16);
    particles.add(pShock);
    pShock.disperse = true;
    pShock.disperseSize = 24.0;
    pShock.fadeWarp = Particle.FADE_CUBE;
    
    // Create temporary light source
    DAGTransform dagLight = new DAGTransform(pos.x, pos.y, pos.z,  0,  1,1,1);
    Light xLight = new Light( dagLight, 1.0, colExplosion );
    lights.add(xLight);
    // Animate light
    dagLight.useSX = true;
    DAGTransform key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform key2 = new DAGTransform(0,0,0, 0, 0,1,1);
    Animator a = dagLight.makeAnimator(key1, key2);
    a.setPeriod(60.0);
    a.setType(Animator.ANIM_TWEEN_SMOOTH);
    anim.add(a);
    
    // Accelerate explosion rate
    explodeTimerInterval *= 0.8;
  }
  // makeExplosion
  
  
  
  public void addSlave(Ship slave)
  // Attach a ship to this one, such as a turret
  {
    // Attach to root (may be overridden later)
    slave.getRoot().snapTo(root);
    slave.getRoot().setParent(root);
    // Comply behaviours
    slave.wrap = false;
    slave.team = team;
    slave.cloakOnInactive = cloakOnInactive;
    // Append to slave list
    slaves.add(slave);
  }
  
  
  public void configureAsPreyA()
  // Configures the ship as a Prey-A model
  {
    // Create the hull
    // This will later be rotated, but is for now held on the origin
    // This makes further construction far more logical
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    Sprite spriteHull = new Sprite(hull, testShipSprite, 16,16, -0.5,-0.5);
    sprites.add( spriteHull );
    spriteHull.setDiffuse(tex_diff);
    spriteHull.setNormal(tex_norm);
    
    
    // Create left turn panel
    DAGTransform leftThruster = new DAGTransform(-2, -4, 0, 0, 1,1,1);
    leftThruster.setParent(hull);
    /* Setup some graphics */
    sprites.add( new Sprite(leftThruster, testShipSprite, 4,4, -0.5,-0.5) );
    // Set sliders for left turn panel
    leftThruster.useR = true;
    DAGTransform leftThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform leftThruster_key2 = new DAGTransform(0,0,0, -QUARTER_PI * 0.5, 1,1,1);
    Animator leftThruster_anim = leftThruster.makeSlider(leftThruster_key1, leftThruster_key2);
    // Register slider to internal controllers
    animTurnRight.add(leftThruster_anim);
    breakpoints.add(leftThruster);
    
    // Create right turn panel
    DAGTransform rightThruster = new DAGTransform(2, -4, 0, 0, 1,1,1);
    rightThruster.setParent(hull);
    /* Setup some graphics */
    sprites.add( new Sprite(rightThruster, testShipSprite, 4,4, -0.5,-0.5) );
    // Set sliders for right turn panel
    rightThruster.useR = true;
    DAGTransform rightThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform rightThruster_key2 = new DAGTransform(0,0,0, QUARTER_PI * 0.5, 1,1,1);
    Animator rightThruster_anim = rightThruster.makeSlider(rightThruster_key1, rightThruster_key2);
    // Register slider to internal controllers
    animTurnLeft.add(rightThruster_anim);
    breakpoints.add(rightThruster);
    
    // Create front light
    DAGTransform frontLightDag = new DAGTransform(0, -4, 0,  0,  1,1,1);
    frontLightDag.setParent(hull);
    Light frontLightLight = new Light( frontLightDag, 0.5, color(128, 192, 255, 255) );
    lights.add(frontLightLight);
    // Animate the light to blink
    frontLightDag.useSX = true;
    DAGTransform frontLightKey1 = new DAGTransform(0,0,0, 0, 0,0,0);
    DAGTransform frontLightKey2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator frontLightAnim = frontLightDag.makeAnimator(frontLightKey1, frontLightKey2);
    frontLightAnim.setType(Animator.ANIM_OSCILLATE);
    frontLightAnim.setPeriod(60);
    frontLightAnim.setDelay( random(1.0) );
    anim.add(frontLightAnim);
    
    // FINALISE
    boltToRoot(hull);
  }
  // configureAsPreyA
  
  
  public void configureAsGunboat()
  // A ship with guns on it
  {
    // Change behaviour
    navMode = NAV_MODE_EXTERNAL;
    destinationRadius = 15.0;
    cloakOnInactive = true;
    colExplosion = color(255,222,192,255);
    
    // Create the hull
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    Sprite sHull = new Sprite(hull, tex_diff, 16,16, -0.5,-0.5);
    sprites.add(sHull);
    sHull.setNormal(tex_norm);
    sHull.setWarp(tex_cloakNorm);
    
    // Create the turrets
    
    // Missile turret
    DAGTransform mtHost = new DAGTransform(-4,4,0, -1, 1,1,1);
    mtHost.setParent(hull);
    /* Setup some graphics */
    sprites.add( new Sprite(mtHost, testShipSprite, 2,2, -0.5,-0.5) );
    // Config turret
    Ship missileTurret = new Ship( new PVector(0,0,0), new PVector(0,0,0), NAV_MODE_TURRET, shipManager, team);
    missileTurret.configureAsTurretMissileA();
    //missileTurret.configureAsTurretBulletA();
    addSlave(missileTurret);
    missileTurret.getRoot().snapTo(mtHost);
    missileTurret.getRoot().setParent(mtHost);
    
    // Laser turret
    DAGTransform ltHost = new DAGTransform(4,4,0, 1, 1,1,1);
    ltHost.setParent(hull);
    /* Setup some graphics */
    sprites.add( new Sprite(ltHost, testShipSprite, 2,2, -0.5,-0.5) );
    // Config turret
    Ship laserTurret = new Ship( new PVector(0,0,0), new PVector(0,0,0), NAV_MODE_TURRET, shipManager, team);
    laserTurret.configureAsTurretBulletA();
    addSlave(laserTurret);
    laserTurret.getRoot().snapTo(ltHost);
    laserTurret.getRoot().setParent(ltHost);
    
    // Create exhaust emitters
    
    // Style exhaust shimmer particle
    DAGTransform exhaustPDag = new DAGTransform(0,0,0, 0, 1,1,1);
    Sprite exhaustS = new Sprite(exhaustPDag, null, 2, 2, -0.5, -0.5);
    exhaustS.setWarp(fx_wrinkle8);
    PVector exhaustVel = new PVector(0.05, 0, 0);
    float exhaustSpin = 0.02;
    float exhaustAgeMax = 180;
    Particle exhaustP = new Particle(exhaustPDag, exhaustS, exhaustVel, exhaustSpin, exhaustAgeMax);
    exhaustP.fadeWarp = Particle.FADE_INOUT_SMOOTH;
    
    // Emitter 1
    DAGTransform em1Host = new DAGTransform(0, 4, 0,  0,  1,1,1);
    em1Host.setParent(hull);
    ParticleEmitter em1 = new ParticleEmitter(em1Host, exhaustP, 0.5);
    emitters.add(em1);
    
    // Drive light 1
    Light em1Light = new Light(em1Host, 1.0, colExplosion);
    lights.add(em1Light);
    
    // Hook emitter to thrust slider
    em1Host.useSX = true;
    DAGTransform em1_key1 = new DAGTransform(0,0,0, 0, 0,0,0);
    DAGTransform em1_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator em1_anim = em1Host.makeSlider(em1_key1, em1_key2);
    // Register slider to internal controllers
    animThrust.add(em1_anim);
        
    // Finalise
    boltToRoot(hull);
  }
  // configureAsGunboat
  
  
  public void configureAsTurretMissileA()
  // This shoots missile-A munitions
  {
    // Set military behaviour
    navMode = NAV_MODE_TURRET;
    thrust = 0.0;
    drag = 0.0;
    turnThrust = 0.0003;
    wrap = false;  // Parent vehicle should handle this
    turretRange.set(turretRange.x, turretRange.y, 40);
    turretAcquisitionArc = turretRange.y - turretRange.x;
    munitionType = MUNITION_MISSILE_A;
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    sprites.add( new Sprite(hull, testShipSprite, 2,2, -0.5,-0.5) );
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsTurretMissileA
  
  
  public void configureAsTurretBulletA()
  // This shoots bullet-A munitions
  {
    // Set military behaviour
    navMode = NAV_MODE_TURRET;
    thrust = 0.0;
    drag = 0.0;
    turnThrust = 0.02;
    turnDrag = 0.9;
    wrap = false;  // Parent vehicle should handle this
    munitionType = MUNITION_BULLET_A;
    firingTimeMax = 10;
    turretRange.set(turretRange.x, turretRange.y, 40);
    turretAcquisitionArc = 0.5;
    reloadTime = 10.0;
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    sprites.add( new Sprite(hull, testShipSprite, 2,2, -0.5,-0.5) );
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsTurretBulletA
  
  
  public void configureAsMissileA()
  // A basic missile, with missile behaviours
  {
    // Set homing behaviour
    navMode = NAV_MODE_HOMING;
    maxVel = 0.6;
    maxTurn = 0.06;
    turnThrust = 0.002;
    turnDrag = 0.9;
    thrust = 0.02;
    radius = 3.0;
    destinationRadius = 1.0;
    explodeTimerInterval = 1.0;
    dismemberTimerInterval = 1.0;
    wrap = false;
    colExplosion = color(255, 192, 127, 255);
    setupExplosionTemplatesB();
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    sprites.add( new Sprite(hull, testShipSprite, 1,2, -0.5,-0.5) );
    
    // Exhaust emitter
    {
      DAGTransform em1Host = new DAGTransform(0, 0, 0,  0,  1,1,1);
      em1Host.setParent(hull);
      ParticleEmitter em1 = new ParticleEmitter(em1Host, null, 2.0);
      emitters.add(em1);
      
      // Drive light 1
      Light em1Light = new Light(em1Host, 0.5, colExplosion);
      lights.add(em1Light);
      
      // PARTICLES
      
      DAGTransform dag = new DAGTransform(0,0,0, 0, 1,1,1);
      Sprite s = new Sprite(dag, null, 0.5, 0.5, -0.5, -0.5);
      PVector vel = new PVector(0.2, 0, 0);
      float spin = 0;
      float ageMax = 30;
      Particle p = new Particle(dag, s, vel, spin, ageMax);
      p.streak = true;
      p.aimAlongMotion = true;
      p.disperse = false;
      p.sprite.setEmissive( fx_streakPC );
      for(int i = 0;  i < 4;  i++)
        em1.addTemplate(p);
      
      // Puffs
      PVector puffVel = new PVector(0.04, 0, 0);
      float puffSpin = 0.04;
      float puffDisperseSize = 4.0;
      float puffAgeMax = 15;
      PVector pr = new PVector(0.5, 0.5);
      
      // Puff 1
      dag = new DAGTransform(0,0,0, 0, 1,1,1);
      s = new Sprite(dag, null, pr.x, pr.y, -0.5,-0.5);
      s.setEmissive(fx_puff1pc);
      p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
      p.disperseSize = puffDisperseSize;
      em1.addTemplate(p);
      
      // Puff 2
      dag = new DAGTransform(0,0,0, 0, 1,1,1);
      s = new Sprite(dag, null, pr.x, pr.y, -0.5,-0.5);
      s.setEmissive(fx_puff2pc);
      p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
      p.disperseSize = puffDisperseSize;
      em1.addTemplate(p);
      
      // Puff 3
      dag = new DAGTransform(0,0,0, 0, 1,1,1);
      s = new Sprite(dag, null, pr.x, pr.y, -0.5,-0.5);
      s.setEmissive(fx_puff3pc);
      p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
      p.disperseSize = puffDisperseSize;
      em1.addTemplate(p);
      
      
      // Spatters
      PVector spatVel = new PVector(0, 0, 0);
      float spatSpin = 0.01;
      float spatDisperseSize = 8.0;
      float spatAgeMax = 30;
      
      // Spatter
      dag = new DAGTransform(0,0,0, 0, 1,1,1);
      s = new Sprite(dag, null, pr.x, pr.y, -0.5,-0.5);
      s.setEmissive(fx_spatterPc);
      p = new Particle(dag, s, spatVel, spatSpin, spatAgeMax);
      p.disperseSize = spatDisperseSize;
      em1.addTemplate(p);
    }
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsMissileA
  
  
  public void configureAsBulletA()
  // A bullet
  {
    // Set bullet behaviour
    navMode = NAV_MODE_BULLET;
    maxVel = 2.0;
    maxTurn = 0.0;
    thrust = 0;
    turnThrust = 0;
    radius = 1.0;
    rateVel = 2.0;
    drag = 1.0;  // No friction
    brake = 0.0;
    targetable = false;
    explodeTimerInterval = 1.0;
    dismemberTimerInterval = 1.0;
    wrap = false;
    colExplosion = color(255, 222, 96, 255);
    setupExplosionTemplatesB();
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    // Core beam
    Sprite bulletMain = new Sprite(hull, null, 0.75, 3, -0.5,-0.5);
    bulletMain.setEmissive(fx_streakPC);
    sprites.add(bulletMain);
    
    // Core light
    Light bulletGlow = new Light(hull, 0.8, colExplosion);
    lights.add(bulletGlow);
    
    // Make it spit sparkles
    /* */
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsBulletA
  
  
  public void boltToRoot(DAGTransform hull)
  // Attach hull to root and rotate accordingly
  {
    // Attach hull to root
    hull.snapTo(root);
    // This is rotated away because I like to build on the Y-axis, but zero rotation is natively the X-axis
    hull.rotate(HALF_PI);
    hull.setParent(root);
  }
  // boltToRoot
  
  
  private void snapToFaceTarget()
  {
    PVector tpos = target.getWorldPosition();
    PVector rpos = root.getWorldPosition();
    PVector diff = PVector.sub(tpos, rpos);
    PVector diff2 = new PVector(diff.x, diff.y);  // Force 2D
    float ang = diff2.heading();
    root.setWorldRotation(ang);
  }
  // snapToFaceTarget
  
  
  public void setupExplosionTemplatesA()
  // Makes the default cool explosion pieces
  {
    explosionTemplates.clear();
    
    // Streak particle
    DAGTransform dag = new DAGTransform(0,0,0, 0, 1,1,1);
    Sprite s = new Sprite(dag, null, 0.35, 0.35, -0.5, -0.5);
    PVector vel = new PVector(1.2, 0, 0);
    float spin = 0;
    float ageMax = 30;
    Particle p = new Particle(dag, s, vel, spin, ageMax);
    p.streak = true;
    p.aimAlongMotion = true;
    p.disperse = false;
    p.sprite.setEmissive(fx_streak);
    for(int i = 0;  i < 16;  i++)
    {
      explosionTemplates.add(p);  // Do it several times to get statistical prevalence
    }
    
    // Rays
    PVector rayVel = new PVector(0,0,0);
    float raySpin = 0.02;
    float rayAgeMax = 30;
    
    // Ray flare 1
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 4,4, -0.5,-0.5);
    s.setEmissive(fx_ray1);
    p = new Particle(dag, s, rayVel, raySpin, rayAgeMax);
    explosionTemplates.add(p);
    
    // Ray flare 2
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 4,4, -0.5,-0.5);
    s.setEmissive(fx_ray2);
    p = new Particle(dag, s, rayVel, raySpin, rayAgeMax);
    explosionTemplates.add(p);
    
    
    // Puffs
    PVector puffVel = new PVector(0.6, 0, 0);
    float puffSpin = 0.04;
    float puffAgeMax = 30;
    
    // Puff 1
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 1,1, -0.5,-0.5);
    s.setEmissive(fx_puff1);
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    // Puff 2
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 1,1, -0.5,-0.5);
    s.setEmissive(fx_puff2);
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    // Puff 3
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 1,1, -0.5,-0.5);
    s.setEmissive(fx_puff3);
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    
    // Spatters
    PVector spatVel = new PVector(0.2, 0, 0);
    float spatSpin = 0.01;
    float spatAgeMax = 60;
    
    // Spatter
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 2,2, -0.5,-0.5);
    s.setEmissive(fx_spatter);
    p = new Particle(dag, s, spatVel, spatSpin, spatAgeMax);
    explosionTemplates.add(p);
    
    // Spatter black
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 2,2, -0.5,-0.5);
    s.setDiffuse(fx_spatterBlack);  // A diffuse effect!
    p = new Particle(dag, s, spatVel, spatSpin, spatAgeMax);
    explosionTemplates.add(p);
    
  }
  // setupExplosionTemplatesA
  
  
  public void setupExplosionTemplatesB()
  // Player team explosions: warmer hues for missiles and plasma bolts
  {
    explosionTemplates.clear();
    
    // Streak particle
    DAGTransform dag = new DAGTransform(0,0,0, 0, 1,1,1);
    Sprite s = new Sprite(dag, null, 0.35, 0.35, -0.5, -0.5);
    PVector vel = new PVector(1.2, 0, 0);
    float spin = 0;
    float ageMax = 30;
    Particle p = new Particle(dag, s, vel, spin, ageMax);
    p.streak = true;
    p.aimAlongMotion = true;
    p.disperse = false;
    p.sprite.setEmissive( fx_streakPC );
    for(int i = 0;  i < 16;  i++)
    {
      explosionTemplates.add(p);  // Do it several times to get statistical prevalence
    }
    
    // Rays
    PVector rayVel = new PVector(0,0,0);
    float raySpin = 0.02;
    float rayAgeMax = 30;
    
    // Ray flare 1
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 4,4, -0.5,-0.5);
    s.setEmissive(fx_ray1pc);
    p = new Particle(dag, s, rayVel, raySpin, rayAgeMax);
    explosionTemplates.add(p);
    
    // Ray flare 2
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 4,4, -0.5,-0.5);
    s.setEmissive(fx_ray2pc);
    p = new Particle(dag, s, rayVel, raySpin, rayAgeMax);
    explosionTemplates.add(p);
    
    
    // Puffs
    PVector puffVel = new PVector(0.6, 0, 0);
    float puffSpin = 0.04;
    float puffAgeMax = 30;
    
    // Puff 1
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 2,2, -0.5,-0.5);
    s.setEmissive(fx_puff1pc);
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    // Puff 2
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 2,2, -0.5,-0.5);
    s.setEmissive(fx_puff2pc);
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    // Puff 3
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 2,2, -0.5,-0.5);
    s.setEmissive(fx_puff3pc);
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    
    // Spatters
    PVector spatVel = new PVector(0.2, 0, 0);
    float spatSpin = 0.01;
    float spatAgeMax = 60;
    
    // Spatter
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 2,2, -0.5,-0.5);
    s.setEmissive(fx_spatterPc);
    p = new Particle(dag, s, spatVel, spatSpin, spatAgeMax);
    explosionTemplates.add(p);
    
    // Spatter black
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 2,2, -0.5,-0.5);
    s.setDiffuse(fx_spatterBlack);  // A diffuse effect!
    p = new Particle(dag, s, spatVel, spatSpin, spatAgeMax);
    explosionTemplates.add(p);
  }
  // setupExplosionTemplatesB
  
  
  public DAGTransform getRoot()
  {  return( root );  }
  
  public ArrayList getFragments()
  {  return( fragments );  }
  
  public void setExternalVector(PVector v)
  {  externalVector = v;  }
}
// Ship
