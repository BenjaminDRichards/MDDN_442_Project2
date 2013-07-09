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
  public static final int NAV_MODE_DRIFT = 7;
  
  // Animation data
  ArrayList animTurnLeft, animTurnRight, animThrust, animWeaponShoot, animWeaponReload, anim;
  ArrayList particles, emitters;
  
  // Destructural data
  float hitpoints, hitpointsMax, hitpointsRegen;
  float damageOnHit;
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
  public static final int MUNITION_BULLET_B = 2;
  public static final int MUNITION_MISSILE_B = 3;
  
  
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
    animWeaponShoot = new ArrayList();
    animWeaponReload = new ArrayList();
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
    turnThrust = 0.0003;
    turnDrag = 0.99;
    turnBrake = turnThrust;
    wrap = true;
    float margin = 1.1;
    float xDimension = 100.0 * margin * width / height;
    float yDimension = 100.0 * margin;
    wrapX = new PVector(-0.5 * xDimension, 0.5 * xDimension, xDimension);  // Low bound, high bound, range
    wrapY = new PVector(-0.5 * yDimension + 50, 0.5 * yDimension + 50, yDimension);  // Low bound, high bound, range
    
    // Destruction data
    hitpoints = 0.0;
    hitpointsMax = 1.5;
    hitpointsRegen = 0.002;
    damageOnHit = 1.0;        // This is only used for munitions, not the ships that fire them.
    breakpoints = new ArrayList();
    fragments = new ArrayList();
    exploding = false;
    pleaseRemove = false;
    explodeTimer = 0;
    explodeTimerInterval = 30;
    dismemberTimer = 0;
    dismemberTimerInterval = 10;
    colExplosion = color(127, 255, 192, 255);
    explosionParticles = 64;
    explosionTemplates = new ArrayList();
    //setupExplosionTemplatesA();
    setupExplosionTemplatesPyrotechnic( color(127, 255, 192, 255) );
    
    // Military data
    invulnerable = false;
    targetable = true;
    this.team = team;
    age = 0;
    ageMax = 240;  // This is only used for munitions
    turretRange = new PVector(-PI / 3.0, PI / 3.0, 60);
    turretAcquisitionArc = 0.5;
    reload = 0;
    reloadTime = 180;
    shooting = false;
    firingTimeMax = 20;
    firingTime = firingTimeMax;
    munitionType = MUNITION_BULLET_A;
    teamCol = color(255,255,255);
    
    // Stealth data
    excitement = 0;  // This must be extracted from slave ships
    excitementDecay = 0.008;
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
    
    // Do aging and time management
    age += tick;
    
    // Weapon cycling
    if(!shooting)
    {      reload = constrain(reload + tick,  0.0, reloadTime);    }
    else
    {
      firingTime = constrain(firingTime + tick, 0.0, firingTimeMax);
      if(firingTimeMax <= firingTime)
      {
        fireWeapon();
        shooting = false;
      }
    }
    
    // Hit point management
    hitpoints = max(hitpoints - hitpointsRegen, 0.0);
    if(hitpointsMax <= hitpoints)
    {
      startExploding();
    }
    
    // Check explosions
    if(exploding)
      doExploding(tick);
    
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
      // Remove on slave death
      if(slave.pleaseRemove)
      {
        i.remove();
      }
    }
  }
  // run
  
  
  public void render(RenderManager renderManager)
  {
    // Do particles first
    Iterator k = particles.iterator();
    while( k.hasNext() )
    {
      Particle p = (Particle) k.next();
      renderManager.addSprite(p.sprite);
    }
    
    // Do sprites
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
  }
  // render
  
  
  
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
      
      // Compute steering power
      float steerPower = constrain( abs(sepAngle - rr) / HALF_PI,  0,1);
      float steerPowerTurn = pow(steerPower, 0.5);
      float steerPowerThrust = 1 - 0.7 * pow(steerPower, 2);
      
      // Turn towards the heading
      if(rr < sepAngle)
      {
        // Turn left
        rateTurn += turnThrust * tick * steerPowerTurn;
      }
      if(sepAngle < rr)
      {
        // Turn right
        rateTurn -= turnThrust * tick * steerPowerTurn;
      }
      
      // Accelerate towards target
      rateVel += thrust * tick * steerPowerThrust;
    }
    
    // When inside region, slow down and match heading
    else
    {
      rateVel  = max( rateVel - brake * tick,  0.0 );
    }
    
    // Apply navigational physics
    rateTurn = constrain(rateTurn, -maxTurn, maxTurn) * pow(turnDrag, tick);
    root.rotate(rateTurn * tick);
    rateVel = constrain(rateVel, -maxVel, maxVel) * pow(drag, tick);
    PVector thrustVector = PVector.fromAngle( root.getWorldRotation() );
    thrustVector.mult(rateVel * tick);
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
      case NAV_MODE_DRIFT:
        target.snapTo(root);
        target.moveLocal(destinationRadius * 2.0, random(-1,1) * 0.1, 0.0);
        break;
      default:
        break;
    }
  }
  // doNavTargeting
  
  
  private void doNavTargetingAvoid()
  // Behaviour that avoids other ships in the manager
  {
    // Place the target comfortably in front of the ship
    target.snapTo(root);
    target.setParent(root);
    target.moveLocal(destinationRadius * 1.1, 0, 0);
    target.setParentToWorld();
    // Introduce some wiggle
    PVector r = PVector.random2D();
    r.mult(1.0);
    target.moveLocal(r.x, r.y, 0.0);
    // Look for nearby obstacles
    float radiusMult = 1.0;
    float detectRadius = radius * radiusMult;
    Ship ship = shipManager.getNearestNeighbourTo( target.getWorldPosition(),  this );
    if(ship != null)
    {
      PVector vecBetween = PVector.sub( target.getWorldPosition(),  ship.getRoot().getWorldPosition() );
      float otherDetectRadius = ship.radius * radiusMult;
      if( vecBetween.mag() < detectRadius + otherDetectRadius)
      {
        target.moveWorld(vecBetween.x * 2.0, vecBetween.y * 2.0, vecBetween.z * 2.0);
      }
    }
  }
  // doNavTargetingAvoid
  
  
  private void doNavTargetingTurret()
  // A turret that aims towards hostile ships
  {
    if(cloaked)  return;  // Everybody knows that cloaks draw power from the weapons array
    
    // Set parent
    // This shouldn't ever be null, but just in case...
    DAGTransform parentDag = root;
    if(root.getParent() != null)
    {
      parentDag = root.getParent();
    }
    
    // Select an enemy target within a certain arc
    ArrayList enemies = shipManager.getEnemiesOf(team);
    PVector rpos = parentDag.getWorldPosition();
    float rang = parentDag.getWorldRotation();
    
    // Determine normalized facing
    float rangN = rang % TWO_PI;
    if(rangN < -PI)  rangN += TWO_PI;
    if(PI < rangN)  rangN -= TWO_PI;
    
    // Placeholder for target
    Ship candidate = null;
    float candidateDeviation = 0.0;
    float candidateWorldBearing = 0.0;
    
    Iterator i = enemies.iterator();
    while( i.hasNext() )
    {
      Ship enemy = (Ship) i.next();
      PVector enemyPos = enemy.getRoot().getWorldPosition();
      PVector vecToEnemy = PVector.sub(enemyPos, rpos);
      float angToEnemy = vecToEnemy.heading();
      float angDiff = angToEnemy - rangN;
      if(angDiff < -PI)  angDiff += TWO_PI;
      if(PI < angDiff)  angDiff -= TWO_PI;
      if( turretRange.x < angDiff  &&  angDiff < turretRange.y  &&  vecToEnemy.mag() < turretRange.z )
      {
        // Valid target
        if( candidate == null  ||  abs(angDiff) < candidateDeviation )
        {
          candidate = enemy;
          candidateDeviation = abs(angDiff);
          candidateWorldBearing = angToEnemy;
        }
      }
    }
    if(candidate != null)
    {
      // Target that vessel
      target.snapTo( candidate.getRoot() );
      
      // Fire at valid targets
      // Find the current heading
      float worldAng = root.getWorldRotation();
      float deviation = (candidateWorldBearing - worldAng) % TWO_PI;
      if(abs(deviation) < turretAcquisitionArc  &&  candidate != null  && !shooting  &&  reloadTime <= reload)
      {
        //fireWeapon();
        
        // Start shooting animation
        shooting = true;
        firingTime = 0;
      }
    }
    else
    {
      // Revert to original orientation
      DAGTransform newTarget = root.getParent();
      float newTargetAng = newTarget.getWorldRotation();
      float newTargetOffset = 100.0;
      target.snapTo( newTarget );
      PVector targetOffset = new PVector( newTargetOffset * cos(newTargetAng),
                                          newTargetOffset * sin(newTargetAng) );
      target.moveWorld(targetOffset.x, targetOffset.y);
    }
  }
  // doNavTargetingTurret
  
  
  private void doNavTargetingHoming()
  // Home in on the nearest enemy and explode
  {
    if(!exploding)
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
          enemy.takeHit(damageOnHit);
        }
      }
      // Time out
      if(ageMax < age)
      {
       startExploding();
      }
    }
  }
  // doNavTargetingHoming
  
  
  private void doNavTargetingBullet()
  // Fly unaltered until you hit an enemy
  {
    if(!exploding)
    {
      Ship enemy = shipManager.getNearestEnemyTo(root.getWorldPosition(), team);
      if(enemy != null  
        &&  enemy.getRoot().getWorldPosition().dist( root.getWorldPosition() ) < enemy.radius + radius)
      {
        // Kill yourself
        startExploding();
        // Kill the enemy too
        enemy.takeHit(damageOnHit);
        // Slow down, you might hit something else
        rateVel = 0;
      }
      
      // Time out
      if(ageMax < age)
      {
       startExploding();
      }
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
    
    // Weapon parameters
    float wpn_shoot = constrain(firingTime / firingTimeMax,  0.0, 1.0);
    float wpn_reload = constrain(reload / reloadTime,  0.0, 1.0);
    
    // Weapon shoot
    Iterator it_wpn_shoot = animWeaponShoot.iterator();
    while( it_wpn_shoot.hasNext() )
    {
      Animator a = (Animator) it_wpn_shoot.next();
      a.setSlider(wpn_shoot);
      a.run(tick);
    }
    // Weapon reload
    Iterator it_wpn_reload = animWeaponReload.iterator();
    while( it_wpn_reload.hasNext() )
    {
      Animator a = (Animator) it_wpn_reload.next();
      a.setSlider(wpn_reload);
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
        cloakActivation = min(cloakActivation + cloakActivationSpeed * tick, 1.0);
      }
      
      // Clamp down weapon activation
      firingTime = firingTimeMax;
      reload = 0;
    }
    else
    {
      if(excitement <= 0)
      {
        // Start cloaking
        if(cloakOnInactive)
        {
          // This means it only cloaks if it's set to, or if it's a slave of a cloaker
          cloaked = true;
        }
      }
      else
      {
        // Power down cloak
        cloakActivation = max(cloakActivation - cloakActivationSpeed * tick, 0.0);
      }
    }
    
    // Manage warp profiles
    // This will override any other warp effects on sprites
    Iterator i = sprites.iterator();
    while( i.hasNext() )
    {
      float aleph = 1 - cloakActivation;
      float baseAlpha = 3 * pow(aleph, 2) - 2 * pow(aleph, 3);
      float warpBase = aleph < 0.5
        ?  aleph * 2
        :  2 - aleph * 2;
      float warpAlpha = 3 * pow(warpBase, 2) - 2 * pow(warpBase, 3);
      
      // Prevent total fade
      baseAlpha = max(baseAlpha, cloakActivation / 64.0);
      warpAlpha = max(warpAlpha, cloakActivation / 64.0);
      
      // Do something absurd to the warp normal tint
      float warpPhase = aleph * TWO_PI * 4.0;
      PVector wd = new PVector( 1.0 - sin(warpPhase ),
        1.0 - sin(warpPhase * TWO_PI / 3.0), 1.0 - sin(warpPhase * TWO_PI * 2.0 / 3.0) );
      wd.mult( 127 * (1.0 - warpAlpha) );
      wd.add( new PVector(255,255,255) );
      
      Sprite s = (Sprite) i.next();
      s.tintDiff = color(255, 255 * baseAlpha);
      s.tintNorm = color(255, 255 * baseAlpha);
      s.tintSpec = color(255, 255 * baseAlpha);
      s.tintEmit = color(255, 255 * baseAlpha);
      s.tintWarp = color(wd.x,wd.y,wd.z, 255 * warpAlpha);  // It turns on, then off
    }
  }
  // doCloaking
  
  
  public void fireWeapon()
  // Perform aggressive emission
  {
    //if(reloadTime < reload  &&  cloakActivation == 0  && !exploding)
    if(cloakActivation == 0.0  &&  !exploding)
    {
      // Weapon is primed
      //shooting = true;
      reload = 0;
      //firingTime = 0;
      // Create and emit munition
      Ship munition = null;
      PVector pos = root.getWorldPosition().get();
      PVector targetPos = target.getWorldPosition().get();
      float rot = root.getWorldRotation();
      switch(munitionType)
      {
        case MUNITION_BULLET_A:
          // Set straight-ahead target
          targetPos = pos.get();
          targetPos.add(radius * 16.0 * cos(rot), radius * 16.0 * sin(rot), 0.0);
          munition = shipManager.makeShip(pos, targetPos, ShipManager.MODEL_BULLET_A, team);
          break;
        case MUNITION_MISSILE_A:
          munition = shipManager.makeShip(pos, targetPos, ShipManager.MODEL_MISSILE_A, team);
          break;
        case MUNITION_BULLET_B:
          // Set straight-ahead target
          targetPos = pos.get();
          targetPos.add(radius * 16.0 * cos(rot), radius * 16.0 * sin(rot), 0.0);
          munition = shipManager.makeShip(pos, targetPos, ShipManager.MODEL_BULLET_B, team);
          break;
        case MUNITION_MISSILE_B:
          munition = shipManager.makeShip(pos, targetPos, ShipManager.MODEL_MISSILE_B, team);
          break;
        default:
          break;
      }
      
      // Elevate excitement
      //excitement = 1.0;
    }
  }
  // fireWeapon
  
  
  public void takeHit(float damage)
  // What to do if you get hit
  {
    if(!invulnerable)
    {
      // I'm using additive HP here because I think it makes more sense.
      // HP starts at 0 and you don't want to lose any.
      hitpoints += damage;
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
      Iterator i = slaves.iterator();
      while( i.hasNext() )
      {
        Ship s = (Ship) i.next();
        s.startExploding();
      }
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
        if( particles.size() <= 0  &&  slaves.size() <= 0 )
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
      sep.normalize();
      PVector randDir = PVector.random3D();
      randDir.mult( 8.0 );
      sep.add(randDir);
      float tumble = random(-1, 1) * 0.02;
      // Normalize and multiply by an acceptable velocity
      sep.normalize();
      sep.mult( random(0.08) );
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
    pShock.disperseSize = 32.0;
    pShock.fadeWarp = Particle.FADE_CUBE;
    
    // Create temporary light source
    DAGTransform dagLight = new DAGTransform(pos.x, pos.y, pos.z,  0,  1,1,1);
    Light xLight = new Light( dagLight, 0.5, colExplosion );
    lights.add(xLight);
    // Animate light
    dagLight.useSX = true;
    DAGTransform key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform key2 = new DAGTransform(0,0,0, 0, 0,1,1);
    Animator a = dagLight.makeAnimator(key1, key2);
    a.setPeriod(30.0);
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
    colExplosion = color(127, 255, 191, 255);
    color colDrive = color(127, 191, 255, 255);
    
    // Setup explosion particles
    explosionTemplates.clear();
    setupExplosionTemplatesPyroAndDebris(colExplosion);
    
    
    // Create the hull
    // This will later be rotated, but is for now held on the origin
    // This makes further construction far more logical
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    Sprite spriteHull = new Sprite(hull, ship_preya_inner_diff, 16,16, -0.5,-0.5);
    spriteHull.setSpecular(ship_preya_inner_diff);
    spriteHull.setNormal(ship_preya_inner_norm);
    
    
    // SUPERSTRUCTURE
    
    // Create prow
    DAGTransform prowDag = new DAGTransform(0, -4 ,0, 0, 1,1,1);
    prowDag.setParent(hull);
    breakpoints.add(prowDag);
    /* Setup some graphics */
    Sprite prowS = new Sprite(prowDag, ship_preya_prow_diff, 8,8, -0.5,-0.5);
    prowS.setSpecular(ship_preya_prow_diff);
    prowS.setNormal(ship_preya_prow_norm);
    
    // Create bridge
    DAGTransform bridgeDag = new DAGTransform(0, 1.4 ,0, 0, 1,1,1);
    bridgeDag.setParent(hull);
    breakpoints.add(bridgeDag);
    /* Setup some graphics */
    Sprite bridgeS = new Sprite(bridgeDag, ship_preya_bridge_diff, 8,8, -0.5,-0.5);
    bridgeS.setSpecular(ship_preya_bridge_diff);
    bridgeS.setNormal(ship_preya_bridge_norm);
    
    // Create drive
    DAGTransform driveDag = new DAGTransform(0, 4 ,0, 0, 1,1,1);
    driveDag.setParent(hull);
    breakpoints.add(driveDag);
    /* Setup some graphics */
    Sprite driveS = new Sprite(driveDag, ship_preya_drive_diff, 8,8, -0.5,-0.5);
    driveS.setSpecular(ship_preya_drive_diff);
    driveS.setNormal(ship_preya_drive_norm);
    // Register drive thrust light
    DAGTransform driveLightDag = new DAGTransform(0,0,0, 0, 1,1,1);
    driveLightDag.snapTo(driveDag);
    driveLightDag.setParent(driveDag);
    driveLightDag.moveWorld(0, 3, 0);
    driveLightDag.useSX = true;
    Light driveLight = new Light( driveLightDag, 0.5, colDrive );
    lights.add(driveLight);
    // Animate that light
    DAGTransform driveLightDag_key1 = new DAGTransform(0,0,0, 0, 0,1,1);
    DAGTransform driveLightDag_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator driveLightDag_anim = driveLightDag.makeSlider(driveLightDag_key1, driveLightDag_key2);
    animThrust.add(driveLightDag_anim);
    // Create exhaust emitters
    // Style exhaust shimmer particle
    DAGTransform exhaustPDag = new DAGTransform(0,0,0, 0, 1,1,1);
    Sprite exhaustS = new Sprite(exhaustPDag, null, 2, 2, -0.5, -0.5);
    exhaustS.setWarp(fx_wrinkle256);
    exhaustS.masterTintWarp = color(255,96);
    PVector exhaustVel = new PVector(0.05, 0, 0);
    float exhaustSpin = 0.02;
    float exhaustAgeMax = 120;
    Particle exhaustP = new Particle(exhaustPDag, exhaustS, exhaustVel, exhaustSpin, exhaustAgeMax);
    exhaustP.fadeWarp = Particle.FADE_INOUT_SMOOTH;
    // Emitter 1
    ParticleEmitter em1 = new ParticleEmitter(driveLightDag, exhaustP, 0.1);
    em1.ageMin = 0.5;
    emitters.add(em1);
    
    
    // THRUSTERS
    
    float thrusterMaxDepression = PI / 6.0;
    
    // Create left turn panel
    DAGTransform thrusterArmLdag = new DAGTransform(-0.5, -6.0, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    thrusterArmLdag.setParent(prowDag);
    /* Setup some graphics */
    Sprite thrusterArmL = new Sprite(thrusterArmLdag, ship_preya_thrusterArmL_diff, 8,8, -0.75,-0.25);
    thrusterArmL.setSpecular(ship_preya_thrusterArmL_diff);
    thrusterArmL.setNormal(ship_preya_thrusterArmL_norm);
    // Set sliders for left turn panel
    thrusterArmLdag.useR = true;
    DAGTransform leftThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform leftThruster_key2 = new DAGTransform(0,0,0, -thrusterMaxDepression, 1,1,1);
    Animator leftThruster_anim = thrusterArmLdag.makeSlider(leftThruster_key1, leftThruster_key2);
    // Register slider to internal controllers
    animTurnRight.add(leftThruster_anim);
    breakpoints.add(thrusterArmLdag);
    
    // Create right turn panel
    DAGTransform thrusterArmRdag = new DAGTransform(0.5, -6.0, 0, 0, 1,1,1);
    thrusterArmRdag.setParent(prowDag);
    /* Setup some graphics */
    Sprite thrusterArmR = new Sprite(thrusterArmRdag, ship_preya_thrusterArmR_diff, 8,8, -0.25,-0.25);
    thrusterArmR.setSpecular(ship_preya_thrusterArmR_diff);
    thrusterArmR.setNormal(ship_preya_thrusterArmR_norm);
    // Set sliders for right turn panel
    thrusterArmRdag.useR = true;
    DAGTransform rightThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform rightThruster_key2 = new DAGTransform(0,0,0, thrusterMaxDepression, 1,1,1);
    Animator rightThruster_anim = thrusterArmRdag.makeSlider(rightThruster_key1, rightThruster_key2);
    // Register slider to internal controllers
    animTurnLeft.add(rightThruster_anim);
    breakpoints.add(thrusterArmRdag);
    
    // Create left thruster
    DAGTransform thrusterLdag = new DAGTransform(-2.9, -2.3, 0, 0, 1,1,1);
    thrusterLdag.setParent(thrusterArmLdag);
    /* Setup some graphics */
    Sprite thrusterL = new Sprite(thrusterLdag, ship_preya_thrusterL_diff, 4,4, -0.5,-0.5);
    thrusterL.setSpecular(ship_preya_thrusterL_diff);
    thrusterL.setNormal(ship_preya_thrusterL_norm);
    // Set sliders for left turn panel
    thrusterLdag.useR = true;
    DAGTransform thrusterLdag_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform thrusterLdag_key2 = new DAGTransform(0,0,0, thrusterMaxDepression, 1,1,1);
    Animator thrusterLdag_anim = thrusterLdag.makeSlider(thrusterLdag_key1, thrusterLdag_key2);
    // Register slider to internal controllers
    animTurnRight.add(thrusterLdag_anim);
    // Attach nozzle light
    DAGTransform thrusterLLightDag = new DAGTransform(0,0,0, 0, 1,1,1);
    thrusterLLightDag.snapTo(thrusterLdag);
    thrusterLLightDag.setParent(thrusterLdag);
    thrusterLLightDag.moveWorld(-0.1, 0, 0);
    thrusterLLightDag.useSX = true;
    Light thrusterLLight = new Light( thrusterLLightDag, 0.3, colDrive );
    lights.add(thrusterLLight);
    // Animate that light
    DAGTransform thrusterLLightDag_key1 = new DAGTransform(0,0,0, 0, 0,1,1);
    DAGTransform thrusterLLightDag_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator thrusterLLightDag_anim = thrusterLLightDag.makeSlider(thrusterLLightDag_key1, thrusterLLightDag_key2);
    animTurnRight.add(thrusterLLightDag_anim);
    
    // Create right thruster
    DAGTransform thrusterRdag = new DAGTransform(2.9, -2.3, 0, 0, 1,1,1);
    thrusterRdag.setParent(thrusterArmRdag);
    /* Setup some graphics */
    Sprite thrusterR = new Sprite(thrusterRdag, ship_preya_thrusterR_diff, 4,4, -0.5,-0.5);
    thrusterR.setSpecular(ship_preya_thrusterR_diff);
    thrusterR.setNormal(ship_preya_thrusterR_norm);
    // Set sliders for left turn panel
    thrusterRdag.useR = true;
    DAGTransform thrusterRdag_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform thrusterRdag_key2 = new DAGTransform(0,0,0, -thrusterMaxDepression, 1,1,1);
    Animator thrusterRdag_anim = thrusterRdag.makeSlider(thrusterRdag_key1, thrusterRdag_key2);
    // Register slider to internal controllers
    animTurnLeft.add(thrusterRdag_anim);
    // Attach nozzle light
    DAGTransform thrusterRLightDag = new DAGTransform(0,0,0, 0, 1,1,1);
    thrusterRLightDag.snapTo(thrusterRdag);
    thrusterRLightDag.setParent(thrusterRdag);
    thrusterRLightDag.moveWorld(0.1, 0, 0);
    thrusterRLightDag.useSX = true;
    Light thrusterRLight = new Light( thrusterRLightDag, 0.3, colDrive );
    lights.add(thrusterRLight);
    // Animate that light
    DAGTransform thrusterRLightDag_key1 = new DAGTransform(0,0,0, 0, 0,1,1);
    DAGTransform thrusterRLightDag_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator thrusterRLightDag_anim = thrusterRLightDag.makeSlider(thrusterRLightDag_key1, thrusterRLightDag_key2);
    animTurnLeft.add(thrusterRLightDag_anim);
    
    // Front maneuver jets
    
    float jetScale = 4.0;
    
    // Left jet
    DAGTransform jetLDag = new DAGTransform(0.0, 0.0, 0.0,  -HALF_PI,  1,1,1);
    jetLDag.snapTo(thrusterLdag);
    jetLDag.setParent(thrusterLdag);
    jetLDag.rotate( -HALF_PI );  // Because of snapping
    jetLDag.moveWorld(-0.5, 0.25);
    jetLDag.useSX = true;  jetLDag.useSY = true;  jetLDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetLS = new Sprite(jetLDag, null, jetScale,jetScale, -0.5,-1.0);
    jetLS.setEmissive(fx_jet);
    jetLS.masterTintEmit = colDrive;
    // Set animators
    DAGTransform jet_key1 = new DAGTransform(0,0,0, 0, 0,0,0);
    DAGTransform jet_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator jetLDag_anim = jetLDag.makeSlider( jet_key1, jet_key2 );
    animTurnRight.add( jetLDag_anim );
    
    // Right jet
    DAGTransform jetRDag = new DAGTransform(0.0, 0.0, 0.0,  HALF_PI,  1,1,1);
    jetRDag.snapTo(thrusterRdag);
    jetRDag.setParent(thrusterRdag);
    jetRDag.rotate( HALF_PI );  // Because of snapping
    jetRDag.moveWorld(0.5, 0.25);
    jetRDag.useSX = true;  jetRDag.useSY = true;  jetRDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetRS = new Sprite(jetRDag, null, jetScale,jetScale, -0.5,-1.0);
    jetRS.setEmissive(fx_jet);
    jetRS.masterTintEmit = colDrive;
    // Set animators
    Animator jetRDag_anim = jetRDag.makeSlider( jet_key1, jet_key2 );
    animTurnLeft.add( jetRDag_anim );
    
    // Rear maneuver jets
    
    // Left jet
    DAGTransform jetLBackDag = new DAGTransform(0.0, 0.0, 0.0,  -HALF_PI,  1,1,1);
    jetLBackDag.snapTo(driveDag);
    jetLBackDag.setParent(driveDag);
    jetLBackDag.rotate( -HALF_PI * 1.5 );  // Because of snapping
    jetLBackDag.moveWorld(-1.0, 1.0);
    jetLBackDag.useSX = true;  jetLBackDag.useSY = true;  jetLBackDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetLBackS = new Sprite(jetLBackDag, null, jetScale,jetScale, -0.5,-1.0);
    jetLBackS.setEmissive(fx_jet);
    jetLBackS.masterTintEmit = colDrive;
    // Set animators
    Animator jetLBackDag_anim = jetLBackDag.makeSlider( jet_key1, jet_key2 );
    animTurnLeft.add( jetLBackDag_anim );
    
    // Right jet
    DAGTransform jetRBackDag = new DAGTransform(0.0, 0.0, 0.0,  HALF_PI,  1,1,1);
    jetRBackDag.snapTo(driveDag);
    jetRBackDag.setParent(driveDag);
    jetRBackDag.rotate( HALF_PI * 1.5 );  // Because of snapping
    jetRBackDag.moveWorld(1.0, 1.0);
    jetRBackDag.useSX = true;  jetRBackDag.useSY = true;  jetRBackDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetRBackS = new Sprite(jetRBackDag, null, jetScale,jetScale, -0.5,-1.0);
    jetRBackS.setEmissive(fx_jet);
    jetRBackS.masterTintEmit = colDrive;
    // Set animators
    Animator jetRBackDag_anim = jetRBackDag.makeSlider( jet_key1, jet_key2 );
    animTurnRight.add( jetRBackDag_anim );
    
    
    // MOTORS
    
    float motorDelay = random(1.0);  // Gives each ship a unique phase
    float motorFreq = random(165, 195);
    
    // Create left motor 1
    DAGTransform motor1Ldag = new DAGTransform(-1, -0.5, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    motor1Ldag.setParent(hull);
    /* Setup some graphics */
    Sprite motor1LS = new Sprite(motor1Ldag, ship_preya_motor1L_diff, 8,8, -0.75,-0.25);
    motor1LS.setSpecular(ship_preya_motor1L_diff);
    motor1LS.setNormal(ship_preya_motor1L_norm);
    // Set sliders for left turn panel
    motor1Ldag.useR = true;
    DAGTransform motor1Ldag_key1 = new DAGTransform(0,0,0, 0.2, 1,1,1);
    DAGTransform motor1Ldag_key2 = new DAGTransform(0,0,0, -0.2, 1,1,1);
    Animator motor1Ldag_anim = motor1Ldag.makeAnimator(motor1Ldag_key1, motor1Ldag_key2);
    motor1Ldag_anim.delay = motorDelay;
    motor1Ldag_anim.period = motorFreq;
    motor1Ldag_anim.type = Animator.ANIM_OSCILLATE;
    // Register slider to internal controllers
    anim.add(motor1Ldag_anim);
    breakpoints.add(motor1Ldag);
    
    // Create right motor 1
    DAGTransform motor1Rdag = new DAGTransform(1, -0.5, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    motor1Rdag.setParent(hull);
    /* Setup some graphics */
    Sprite motor1RS = new Sprite(motor1Rdag, ship_preya_motor1R_diff, 8,8, -0.25,-0.25);
    motor1RS.setSpecular(ship_preya_motor1R_diff);
    motor1RS.setNormal(ship_preya_motor1R_norm);
    // Set sliders for left turn panel
    motor1Rdag.useR = true;
    DAGTransform motor1Rdag_key1 = new DAGTransform(0,0,0, -0.2, 1,1,1);
    DAGTransform motor1Rdag_key2 = new DAGTransform(0,0,0, 0.2, 1,1,1);
    Animator motor1Rdag_anim = motor1Rdag.makeAnimator(motor1Rdag_key1, motor1Rdag_key2);
    motor1Rdag_anim.delay = motorDelay;
    motor1Rdag_anim.period = motorFreq;
    motor1Rdag_anim.type = Animator.ANIM_OSCILLATE;
    // Register slider to internal controllers
    anim.add(motor1Rdag_anim);
    breakpoints.add(motor1Rdag);
    
    // Create left motor 2
    DAGTransform motor2Ldag = new DAGTransform(-1.5, 1.5, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    motor2Ldag.setParent(hull);
    /* Setup some graphics */
    Sprite motor2LS = new Sprite(motor2Ldag, ship_preya_motor2L_diff, 8,8, -0.5,-0.5);
    motor2LS.setNormal(ship_preya_motor2L_norm);
    motor2LS.setSpecular(ship_preya_motor2L_diff);
    // Set sliders
    motor2Ldag.useR = true;
    DAGTransform motor2Ldag_key1 = new DAGTransform(0,0,0, 0.2, 1,1,1);
    DAGTransform motor2Ldag_key2 = new DAGTransform(0,0,0, -0.2, 1,1,1);
    Animator motor2Ldag_anim = motor2Ldag.makeAnimator(motor2Ldag_key1, motor2Ldag_key2);
    motor2Ldag_anim.delay = motorDelay - HALF_PI;;
    motor2Ldag_anim.period = motorFreq;
    motor2Ldag_anim.type = Animator.ANIM_OSCILLATE;
    // Register slider to internal controllers
    anim.add(motor2Ldag_anim);
    breakpoints.add(motor2Ldag);
    
    // Create right motor 2
    DAGTransform motor2Rdag = new DAGTransform(1.5, 1.5, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    motor2Rdag.setParent(hull);
    /* Setup some graphics */
    Sprite motor2RS = new Sprite(motor2Rdag, ship_preya_motor2R_diff, 8,8, -0.5,-0.5);
    motor2RS.setSpecular(ship_preya_motor2R_diff);
    motor2RS.setNormal(ship_preya_motor2R_norm);
    // Set sliders
    motor2Rdag.useR = true;
    DAGTransform motor2Rdag_key1 = new DAGTransform(0,0,0, -0.2, 1,1,1);
    DAGTransform motor2Rdag_key2 = new DAGTransform(0,0,0, 0.2, 1,1,1);
    Animator motor2Rdag_anim = motor2Rdag.makeAnimator(motor2Rdag_key1, motor2Rdag_key2);
    motor2Rdag_anim.delay = motorDelay - HALF_PI;
    motor2Rdag_anim.period = motorFreq;
    motor2Rdag_anim.type = Animator.ANIM_OSCILLATE;
    // Register slider to internal controllers
    anim.add(motor2Rdag_anim);
    breakpoints.add(motor2Rdag);
    
    // Create left motor 3
    DAGTransform motor3Ldag = new DAGTransform(-1.0, 3.1, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    motor3Ldag.setParent(hull);
    /* Setup some graphics */
    Sprite motor3LS = new Sprite(motor3Ldag, ship_preya_motor3L_diff, 8,8, -0.5,-0.5);
    motor3LS.setNormal(ship_preya_motor3L_norm);
    motor3LS.setSpecular(ship_preya_motor3L_diff);
    // Set sliders
    motor3Ldag.useR = true;
    DAGTransform motor3Ldag_key1 = new DAGTransform(0,0,0, 0.2, 1,1,1);
    DAGTransform motor3Ldag_key2 = new DAGTransform(0,0,0, -0.2, 1,1,1);
    Animator motor3Ldag_anim = motor3Ldag.makeAnimator(motor3Ldag_key1, motor3Ldag_key2);
    motor3Ldag_anim.delay = motorDelay - PI;;
    motor3Ldag_anim.period = motorFreq;
    motor3Ldag_anim.type = Animator.ANIM_OSCILLATE;
    // Register slider to internal controllers
    anim.add(motor3Ldag_anim);
    breakpoints.add(motor3Ldag);
    
    // Create right motor 3
    DAGTransform motor3Rdag = new DAGTransform(1.0, 3.1, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    motor3Rdag.setParent(hull);
    /* Setup some graphics */
    Sprite motor3RS = new Sprite(motor3Rdag, ship_preya_motor3R_diff, 8,8, -0.5,-0.5);
    motor3RS.setNormal(ship_preya_motor3R_norm);
    motor3RS.setSpecular(ship_preya_motor3R_diff);
    // Set sliders
    motor3Rdag.useR = true;
    DAGTransform motor3Rdag_key1 = new DAGTransform(0,0,0, -0.2, 1,1,1);
    DAGTransform motor3Rdag_key2 = new DAGTransform(0,0,0, 0.2, 1,1,1);
    Animator motor3Rdag_anim = motor3Rdag.makeAnimator(motor3Rdag_key1, motor3Rdag_key2);
    motor3Rdag_anim.delay = motorDelay - PI;
    motor3Rdag_anim.period = motorFreq;
    motor3Rdag_anim.type = Animator.ANIM_OSCILLATE;
    // Register slider to internal controllers
    anim.add(motor3Rdag_anim);
    breakpoints.add(motor3Rdag);
    
    
    // Laser turret
    DAGTransform ltHost = new DAGTransform(0,0,0, -HALF_PI, 1,1,1);    // Rotated to face forward
    ltHost.snapTo(prowDag);
    ltHost.setParent(prowDag);
    ltHost.rotate(-HALF_PI);    // Restore after snap
    ltHost.moveWorld(0.0, 2.0, 0.0);
    breakpoints.add(ltHost);
    // Config turret
    Ship laserTurret = new Ship( new PVector(0,0,0), new PVector(0,0,0), NAV_MODE_TURRET, shipManager, team);
    laserTurret.configureAsTurretBulletA();
    addSlave(laserTurret);
    laserTurret.getRoot().snapTo(ltHost);
    laserTurret.getRoot().setParent(ltHost);
    
    
    
    // FINALISE
    boltToRoot(hull);
    
    // Add sprites in order
    sprites.add( spriteHull );
    sprites.add( motor3LS );
    sprites.add( motor3RS );
    sprites.add( driveS );
    sprites.add( jetLS );
    sprites.add( jetRS );
    sprites.add( jetLBackS );
    sprites.add( jetRBackS );
    sprites.add( thrusterL );
    sprites.add( thrusterR );
    sprites.add( thrusterArmL );
    sprites.add( thrusterArmR );
    sprites.add( motor2LS );
    sprites.add( motor2RS );
    sprites.add( motor1LS );
    sprites.add( motor1RS );
    sprites.add( prowS );
    sprites.add( bridgeS );
  }
  // configureAsPreyA
  
  
  public void configureAsGunboat()
  // A ship with guns on it
  {
    // Change behaviour
    navMode = NAV_MODE_AVOID;
    radius = 5;
    destinationRadius = 15.0;
    thrust = 0.0015;
    turnThrust = 0.0002;
    //cloakOnInactive = true;
    colExplosion = color(255,222,192,255);
    
    color colDrive = color(255,222,192, 255);
    
    // Setup explosion particles
    explosionTemplates.clear();
    setupExplosionTemplatesPyroAndDebris(colExplosion);
    
    
    // Create the hull
    // This will later be rotated, but is for now held on the origin
    // This makes further construction far more logical
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    Sprite spriteHull = new Sprite(hull, ship_preya_inner_diff, 24,24, -0.5,-0.5);
    spriteHull.setNormal(ship_preya_inner_norm);
    spriteHull.setWarp(ship_preya_inner_warp);
    
    
    
    // SUPERSTRUCTURE
    
    // Create prow
    DAGTransform prowDag = new DAGTransform(0, -6 ,0, 0, 1,1,1);
    prowDag.setParent(hull);
    breakpoints.add(prowDag);
    /* Setup some graphics */
    Sprite prowS = new Sprite(prowDag, ship_preya_prow_diff, 8,8, -0.5,-0.5);
    prowS.setSpecular(ship_preya_prow_diff);
    prowS.setNormal(ship_preya_prow_norm);
    prowS.setWarp(ship_preya_prow_warp);
    
    // Create bridge
    DAGTransform bridgeDag = new DAGTransform(0, 1.4 ,0, 0, 1,1,1);
    bridgeDag.setParent(hull);
    breakpoints.add(bridgeDag);
    /* Setup some graphics */
    Sprite bridgeS = new Sprite(bridgeDag, ship_preya_bridge_diff, 12,12, -0.5,-0.5);
    bridgeS.setSpecular(ship_preya_bridge_diff);
    bridgeS.setNormal(ship_preya_bridge_norm);
    bridgeS.setWarp(ship_preya_bridge_warp);
    
    // Create drive
    DAGTransform driveDag = new DAGTransform(0, 4 ,0, 0, 1,1,1);
    driveDag.setParent(hull);
    breakpoints.add(driveDag);
    /* Setup some graphics */
    Sprite driveS = new Sprite(driveDag, ship_preya_drive_diff, 12,12, -0.5,-0.5);
    driveS.setSpecular(ship_preya_drive_diff);
    driveS.setNormal(ship_preya_drive_norm);
    driveS.setWarp(ship_preya_drive_warp);
    // Register drive thrust light
    DAGTransform driveLightDag = new DAGTransform(0,0,0, 0, 1,1,1);
    driveLightDag.snapTo(driveDag);
    driveLightDag.setParent(driveDag);
    driveLightDag.moveWorld(0, 9.0, 0);
    driveLightDag.useSX = true;
    Light driveLight = new Light( driveLightDag, 1.0, colDrive );
    lights.add(driveLight);
    // Animate that light
    DAGTransform driveLightDag_key1 = new DAGTransform(0,0,0, 0, 0,1,1);
    DAGTransform driveLightDag_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator driveLightDag_anim = driveLightDag.makeSlider(driveLightDag_key1, driveLightDag_key2);
    animThrust.add(driveLightDag_anim);
    // Create exhaust emitters
    // Style exhaust shimmer particle
    DAGTransform exhaustPDag = new DAGTransform(0,0,0, 0, 1,1,1);
    Sprite exhaustS = new Sprite(exhaustPDag, null, 2, 2, -0.5, -0.5);
    exhaustS.setWarp(fx_wrinkle256);
    exhaustS.masterTintWarp = color(255,96);
    PVector exhaustVel = new PVector(0.05, 0, 0);
    float exhaustSpin = 0.02;
    float exhaustAgeMax = 120;
    Particle exhaustP = new Particle(exhaustPDag, exhaustS, exhaustVel, exhaustSpin, exhaustAgeMax);
    exhaustP.fadeWarp = Particle.FADE_INOUT_SMOOTH;
    // Emitter 1
    ParticleEmitter em1 = new ParticleEmitter(driveLightDag, exhaustP, 0.1);
    em1.ageMin = 0.5;
    emitters.add(em1);
    
    
    // WINGS
    
    // Create left wing
    DAGTransform wingLdag = new DAGTransform(-4, 2, 0, 0, 1,1,1);
    wingLdag.setParent(prowDag);
    /* Setup some graphics */
    Sprite wingLS = new Sprite(wingLdag, ship_preya_thrusterArmL_diff, 16,16, -0.5,-0.5);
    wingLS.setSpecular(ship_preya_thrusterArmL_diff);
    wingLS.setNormal(ship_preya_thrusterArmL_norm);
    wingLS.setWarp(ship_preya_thrusterArmL_warp);
    
    // Create right wing
    DAGTransform wingRdag = new DAGTransform(4, 2, 0, 0, 1,1,1);
    wingRdag.setParent(prowDag);
    /* Setup some graphics */
    Sprite wingRS = new Sprite(wingRdag, ship_preya_thrusterArmR_diff, 16,16, -0.5,-0.5);
    wingRS.setSpecular(ship_preya_thrusterArmR_diff);
    wingRS.setNormal(ship_preya_thrusterArmR_norm);
    wingRS.setWarp(ship_preya_thrusterArmR_warp);
    
    
    // THRUSTERS
    
    float thrusterMaxDepression = PI / 6.0;
    
    // Create left turn panel
    DAGTransform thrusterArmLdag = new DAGTransform(-0.5, -8.0, 0, 0, 1,1,1);  // Slightly offset: +1,+1 due odd sprite center
    thrusterArmLdag.setParent(prowDag);
    /* Setup some graphics */
    Sprite thrusterArmL = new Sprite(thrusterArmLdag, ship_preya_thrusterArmL_diff, 8,8, -0.75,-0.25);
    thrusterArmL.setSpecular(ship_preya_thrusterArmL_diff);
    thrusterArmL.setNormal(ship_preya_thrusterArmL_norm);
    thrusterArmL.setWarp(ship_preya_thrusterArmL_warp);
    // Set sliders for left turn panel
    thrusterArmLdag.useR = true;
    DAGTransform leftThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform leftThruster_key2 = new DAGTransform(0,0,0, -thrusterMaxDepression, 1,1,1);
    Animator leftThruster_anim = thrusterArmLdag.makeSlider(leftThruster_key1, leftThruster_key2);
    // Register slider to internal controllers
    animTurnRight.add(leftThruster_anim);
    breakpoints.add(thrusterArmLdag);
    
    // Create right turn panel
    DAGTransform thrusterArmRdag = new DAGTransform(0.5, -8.0, 0, 0, 1,1,1);
    thrusterArmRdag.setParent(prowDag);
    /* Setup some graphics */
    Sprite thrusterArmR = new Sprite(thrusterArmRdag, ship_preya_thrusterArmR_diff, 8,8, -0.25,-0.25);
    thrusterArmR.setSpecular(ship_preya_thrusterArmR_diff);
    thrusterArmR.setNormal(ship_preya_thrusterArmR_norm);
    thrusterArmR.setWarp(ship_preya_thrusterArmR_warp);
    // Set sliders for right turn panel
    thrusterArmRdag.useR = true;
    DAGTransform rightThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform rightThruster_key2 = new DAGTransform(0,0,0, thrusterMaxDepression, 1,1,1);
    Animator rightThruster_anim = thrusterArmRdag.makeSlider(rightThruster_key1, rightThruster_key2);
    // Register slider to internal controllers
    animTurnLeft.add(rightThruster_anim);
    breakpoints.add(thrusterArmRdag);
    
    // Create left thruster
    DAGTransform thrusterLdag = new DAGTransform(-2.9, -4.3, 0, 0, 1,1,1);
    thrusterLdag.setParent(thrusterArmLdag);
    /* Setup some graphics */
    Sprite thrusterL = new Sprite(thrusterLdag, ship_preya_thrusterL_diff, 4,4, -0.5,-0.5);
    thrusterL.setSpecular(ship_preya_thrusterL_diff);
    thrusterL.setNormal(ship_preya_thrusterL_norm);
    thrusterL.setWarp(ship_preya_thrusterL_warp);
    // Set sliders for left turn panel
    thrusterLdag.useR = true;
    DAGTransform thrusterLdag_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform thrusterLdag_key2 = new DAGTransform(0,0,0, thrusterMaxDepression, 1,1,1);
    Animator thrusterLdag_anim = thrusterLdag.makeSlider(thrusterLdag_key1, thrusterLdag_key2);
    // Register slider to internal controllers
    animTurnRight.add(thrusterLdag_anim);
    // Attach nozzle light
    DAGTransform thrusterLLightDag = new DAGTransform(0,0,0, 0, 1,1,1);
    thrusterLLightDag.snapTo(thrusterLdag);
    thrusterLLightDag.setParent(thrusterLdag);
    thrusterLLightDag.moveWorld(-0.1, 0, 0);
    thrusterLLightDag.useSX = true;
    Light thrusterLLight = new Light( thrusterLLightDag, 0.3, colDrive );
    lights.add(thrusterLLight);
    // Animate that light
    DAGTransform thrusterLLightDag_key1 = new DAGTransform(0,0,0, 0, 0,1,1);
    DAGTransform thrusterLLightDag_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator thrusterLLightDag_anim = thrusterLLightDag.makeSlider(thrusterLLightDag_key1, thrusterLLightDag_key2);
    animTurnRight.add(thrusterLLightDag_anim);
    
    // Create right thruster
    DAGTransform thrusterRdag = new DAGTransform(2.9, -4.3, 0, 0, 1,1,1);
    thrusterRdag.setParent(thrusterArmRdag);
    /* Setup some graphics */
    Sprite thrusterR = new Sprite(thrusterRdag, ship_preya_thrusterR_diff, 4,4, -0.5,-0.5);
    thrusterR.setSpecular(ship_preya_thrusterR_diff);
    thrusterR.setNormal(ship_preya_thrusterR_norm);
    thrusterR.setWarp(ship_preya_thrusterR_warp);
    // Set sliders for left turn panel
    thrusterRdag.useR = true;
    DAGTransform thrusterRdag_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform thrusterRdag_key2 = new DAGTransform(0,0,0, -thrusterMaxDepression, 1,1,1);
    Animator thrusterRdag_anim = thrusterRdag.makeSlider(thrusterRdag_key1, thrusterRdag_key2);
    // Register slider to internal controllers
    animTurnLeft.add(thrusterRdag_anim);
    // Attach nozzle light
    DAGTransform thrusterRLightDag = new DAGTransform(0,0,0, 0, 1,1,1);
    thrusterRLightDag.snapTo(thrusterRdag);
    thrusterRLightDag.setParent(thrusterRdag);
    thrusterRLightDag.moveWorld(0.1, 0, 0);
    thrusterRLightDag.useSX = true;
    Light thrusterRLight = new Light( thrusterRLightDag, 0.3, colDrive );
    lights.add(thrusterRLight);
    // Animate that light
    DAGTransform thrusterRLightDag_key1 = new DAGTransform(0,0,0, 0, 0,1,1);
    DAGTransform thrusterRLightDag_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator thrusterRLightDag_anim = thrusterRLightDag.makeSlider(thrusterRLightDag_key1, thrusterRLightDag_key2);
    animTurnLeft.add(thrusterRLightDag_anim);
    
    // Front maneuver jets
    
    float jetScale = 4.0;
    
    // Left jet
    DAGTransform jetLDag = new DAGTransform(0.0, 0.0, 0.0,  -HALF_PI,  1,1,1);
    jetLDag.snapTo(thrusterLdag);
    jetLDag.setParent(thrusterLdag);
    jetLDag.rotate( -HALF_PI );  // Because of snapping
    jetLDag.moveWorld(-0.5, 0.25);
    jetLDag.useSX = true;  jetLDag.useSY = true;  jetLDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetLS = new Sprite(jetLDag, null, jetScale,jetScale, -0.5,-1.0);
    jetLS.setEmissive(fx_jet);
    jetLS.masterTintEmit = colDrive;
    // Set animators
    DAGTransform jet_key1 = new DAGTransform(0,0,0, 0, 0,0,0);
    DAGTransform jet_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator jetLDag_anim = jetLDag.makeSlider( jet_key1, jet_key2 );
    animTurnRight.add( jetLDag_anim );
    
    // Right jet
    DAGTransform jetRDag = new DAGTransform(0.0, 0.0, 0.0,  HALF_PI,  1,1,1);
    jetRDag.snapTo(thrusterRdag);
    jetRDag.setParent(thrusterRdag);
    jetRDag.rotate( HALF_PI );  // Because of snapping
    jetRDag.moveWorld(0.5, 0.25);
    jetRDag.useSX = true;  jetRDag.useSY = true;  jetRDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetRS = new Sprite(jetRDag, null, jetScale,jetScale, -0.5,-1.0);
    jetRS.setEmissive(fx_jet);
    jetRS.masterTintEmit = colDrive;
    // Set animators
    Animator jetRDag_anim = jetRDag.makeSlider( jet_key1, jet_key2 );
    animTurnLeft.add( jetRDag_anim );
    
    // Rear maneuver jets
    
    // Left jet
    DAGTransform jetLBackDag = new DAGTransform(0.0, 0.0, 0.0,  -HALF_PI,  1,1,1);
    jetLBackDag.snapTo(driveDag);
    jetLBackDag.setParent(driveDag);
    jetLBackDag.rotate( -HALF_PI * 1.5 );  // Because of snapping
    jetLBackDag.moveWorld(-2.0, 2.0);
    jetLBackDag.useSX = true;  jetLBackDag.useSY = true;  jetLBackDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetLBackS = new Sprite(jetLBackDag, null, jetScale,jetScale, -0.5,-1.0);
    jetLBackS.setEmissive(fx_jet);
    jetLBackS.masterTintEmit = colDrive;
    // Set animators
    Animator jetLBackDag_anim = jetLBackDag.makeSlider( jet_key1, jet_key2 );
    animTurnLeft.add( jetLBackDag_anim );
    
    // Right jet
    DAGTransform jetRBackDag = new DAGTransform(0.0, 0.0, 0.0,  HALF_PI,  1,1,1);
    jetRBackDag.snapTo(driveDag);
    jetRBackDag.setParent(driveDag);
    jetRBackDag.rotate( HALF_PI * 1.5 );  // Because of snapping
    jetRBackDag.moveWorld(2.0, 2.0);
    jetRBackDag.useSX = true;  jetRBackDag.useSY = true;  jetRBackDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetRBackS = new Sprite(jetRBackDag, null, jetScale,jetScale, -0.5,-1.0);
    jetRBackS.setEmissive(fx_jet);
    jetRBackS.masterTintEmit = colDrive;
    // Set animators
    Animator jetRBackDag_anim = jetRBackDag.makeSlider( jet_key1, jet_key2 );
    animTurnRight.add( jetRBackDag_anim );
    
    
    // TURRETS
    
    // Missile turret
    DAGTransform mtHost = new DAGTransform(-5,5,0, -HALF_PI, 1,1,1);    // Rotated to face forward
    mtHost.setParent(hull);
    breakpoints.add(mtHost);
    // Config turret
    Ship missileTurret = new Ship( new PVector(0,0,0), new PVector(0,0,0), NAV_MODE_TURRET, shipManager, team);
    missileTurret.configureAsTurretMissileB();
    addSlave(missileTurret);
    missileTurret.getRoot().snapTo(mtHost);
    missileTurret.getRoot().setParent(mtHost);
    
    // Laser turret
    DAGTransform ltHost = new DAGTransform(5,5,0, -HALF_PI, 1,1,1);    // Rotated to face forward
    ltHost.setParent(hull);
    breakpoints.add(ltHost);
    // Config turret
    Ship laserTurret = new Ship( new PVector(0,0,0), new PVector(0,0,0), NAV_MODE_TURRET, shipManager, team);
    laserTurret.configureAsTurretBulletB();
    addSlave(laserTurret);
    laserTurret.getRoot().snapTo(ltHost);
    laserTurret.getRoot().setParent(ltHost);
    
    
        
    // Finalise
    boltToRoot(hull);
    
    // Add sprites in order
    sprites.add( spriteHull );
    sprites.add( wingLS );
    sprites.add( wingRS );
    sprites.add( driveS );
    sprites.add( thrusterL );
    sprites.add( thrusterR );
    sprites.add( jetLS );
    sprites.add( jetRS );
    sprites.add( jetLBackS );
    sprites.add( jetRBackS );
    sprites.add( thrusterArmL );
    sprites.add( thrusterArmR );
    sprites.add( bridgeS );
    sprites.add( prowS );
  }
  // configureAsGunboat
  
  
  public void configureAsTurretMissileA()
  // This shoots missile-A munitions in cool plasma
  {
    configureAsTurretMissile( color(127,255,192,255) );
  }
  // configureAsTurretMissileA
  
  
  public void configureAsTurretMissileB()
  // This shoots missile-B munitions in warm plasma
  {
    configureAsTurretMissile( color(255,191,127,255) );
    munitionType = MUNITION_MISSILE_B;
  }
  // configureAsTurretMissileA
  
  
  public void configureAsTurretMissile(color col)
  {
    // Set military behaviour
    navMode = NAV_MODE_TURRET;
    thrust = 0.0;
    drag = 0.0;
    turnThrust = 0.001;
    turnDrag = 0.95;
    wrap = false;  // Parent vehicle should handle this
    munitionType = MUNITION_MISSILE_A;
    firingTimeMax = 20;
    reloadTime = 50;
    turretAcquisitionArc = 0.2;
    colExplosion = col;
    
    setupExplosionTemplatesPyroAndDebris(colExplosion);
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    Sprite hullS = new Sprite(hull, ship_preya_turret_diff, 12,12, -0.5,-0.5);
    hullS.setSpecular(ship_preya_turret_diff);
    hullS.setNormal(ship_preya_turret_norm);
    hullS.setWarp(ship_preya_turret_warp);
    sprites.add(hullS);
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsTurretMissile
  
  
  public void configureAsTurretBulletA()
  // This shoots bullet-A munitions, green energy bolts
  {
    configureAsTurretBullet( color(127,255,191,255) );
  }
  // configureAsTurretBulletA
  
  
  public void configureAsTurretBulletB()
  // This shoots bullet-B munitions, hot plasma bolts
  {
    configureAsTurretBullet( color(255,191,127,255) );
    munitionType = MUNITION_BULLET_B;
  }
  // configureAsTurretBulletA
  
  
  public void configureAsTurretBullet(color col)
  // This shoots bullets
  {
    // Set military behaviour
    navMode = NAV_MODE_TURRET;
    thrust = 0.0;
    drag = 0.0;
    turnThrust = 0.001;
    turnDrag = 0.95;
    wrap = false;  // Parent vehicle should handle this
    munitionType = MUNITION_BULLET_A;
    firingTimeMax = 20.0;
    reloadTime = 50.0;
    turretAcquisitionArc = 0.2;
    colExplosion = col;
    
    setupExplosionTemplatesPyroAndDebris(colExplosion);
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    Sprite hullS = new Sprite(hull, ship_preya_turret_diff, 12,12, -0.5,-0.5);
    hullS.setSpecular(ship_preya_turret_diff);
    hullS.setNormal(ship_preya_turret_norm);
    hullS.setWarp(ship_preya_turret_warp);
    sprites.add(hullS);
    
    // Shooting animation
    DAGTransform muzAuraDag = new DAGTransform(0,0,0, 0, 1,1,1);
    muzAuraDag.snapTo(hull);
    muzAuraDag.setParent(hull);
    muzAuraDag.moveWorld(0.0, -1.0, 0.0);
    ParticleEmitter muzAuraEm = new ParticleEmitter(muzAuraDag, null, 2.0);
    emitters.add(muzAuraEm);
    
    // Setup shooter animator slider
    muzAuraDag.useSX = true;
    DAGTransform muzAuraDag_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform muzAuraDag_key2 = new DAGTransform(0,0,0, 0, 0,1,1);
    Animator muzAuraDag_anim = muzAuraDag.makeSlider( muzAuraDag_key1, muzAuraDag_key2 );
    animWeaponShoot.add( muzAuraDag_anim );
    
    // Setup charge particles
    PVector vel = new PVector(0,0,0);
    float spin = 0.0;
    float ageMax = 40;
    float disperseSize = -1.0;
    
    Sprite pCharge1S = new Sprite(null, null, 8.0,8.0, -0.5,-0.5);
    pCharge1S.setEmissive(fx_ray1);
    pCharge1S.masterTintEmit = colExplosion;
    Particle pCharge1P = new Particle(null, pCharge1S, vel, spin, ageMax);
    pCharge1P.fadeEmit = Particle.FADE_LINEAR_INV;
    pCharge1P.disperseSize = disperseSize;  // Because dispersion is from a base of 1.0
    muzAuraEm.addTemplate( pCharge1P );
    
    Sprite pCharge2S = new Sprite(null, null, 8.0,8.0, -0.5,-0.5);
    pCharge2S.setEmissive(fx_ray2);
    pCharge2S.masterTintEmit = colExplosion;
    Particle pCharge2P = new Particle(null, pCharge2S, vel, spin, ageMax);
    pCharge2P.fadeEmit = Particle.FADE_INOUT_SMOOTH;
    pCharge2P.disperseSize = disperseSize;  // Because dispersion is from a base of 1.0
    muzAuraEm.addTemplate( pCharge2P );
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsTurretBullet
  
  
  public void configureAsMissileA()
  // A basic missile, with missile behaviours
  {
    configureAsMissile( color(127,255,191,255) );
  }
  // configureAsMissileA
  
  
  public void configureAsMissileB()
  {
    configureAsMissile( color(255,191,127,255) );
  }
  // configureAsMissileB
  
  
  public void configureAsMissile(color col)
  {
    // Set homing behaviour
    navMode = NAV_MODE_HOMING;
    maxVel = 0.3;
    maxTurn = 0.06;
    turnThrust = 0.002;
    turnDrag = 0.95;
    thrust = 0.01;
    radius = 3.0;
    destinationRadius = 1.0;
    hitpointsMax = 0.1;
    ageMax = 360;
    explodeTimerInterval = 1.0;
    dismemberTimerInterval = 1.0;
    wrap = false;
    colExplosion = col;
    
    // Setup explosion templates
    explosionTemplates.clear();
    setupExplosionTemplatesPyrotechnic(colExplosion);
    explosionParticles = 128;
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    Sprite hullS = new Sprite(hull, ship_preya_prow_diff, 3,3, -0.5,-0.5);
    hullS.setSpecular(ship_preya_prow_diff);
    hullS.setNormal(ship_preya_prow_norm);
    sprites.add(hullS);
    
    // Maneuver jets
    
    // Left jet
    DAGTransform jetLDag = new DAGTransform(0.0, -1.0, 0.0,  -HALF_PI,  1,1,1);
    jetLDag.setParent(hull);
    jetLDag.useSX = true;  jetLDag.useSY = true;  jetLDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetLS = new Sprite(jetLDag, null, 3,3, -0.5,-1.0);
    jetLS.setEmissive(fx_jet);
    jetLS.masterTintEmit = colExplosion;
    sprites.add(jetLS);
    // Set animators
    DAGTransform jet_key1 = new DAGTransform(0,0,0, 0, 0,0,0);
    DAGTransform jet_key2 = new DAGTransform(0,0,0, 0, 1,1,1);
    Animator jetLDag_anim = jetLDag.makeSlider( jet_key1, jet_key2 );
    animTurnRight.add( jetLDag_anim );
    
    // Right jet
    DAGTransform jetRDag = new DAGTransform(0.0, -1.0, 0.0,  HALF_PI,  1,1,1);
    jetRDag.setParent(hull);
    jetRDag.useSX = true;  jetRDag.useSY = true;  jetRDag.useSZ = true;
    /* Setup some graphics */
    Sprite jetRS = new Sprite(jetRDag, null, 3,3, -0.5,-1.0);
    jetRS.setEmissive(fx_jet);
    jetRS.masterTintEmit = colExplosion;
    sprites.add(jetRS);
    // Set animators
    Animator jetRDag_anim = jetRDag.makeSlider( jet_key1, jet_key2 );
    animTurnLeft.add( jetRDag_anim );
    
    // Exhaust emitter
    {
      DAGTransform em1Host = new DAGTransform(0, 0.8, 0,  0,  1,1,1);
      em1Host.setParent(hull);
      ParticleEmitter em1 = new ParticleEmitter(em1Host, null, 8.0);
      emitters.add(em1);
      
      // Drive light 1
      Light em1Light = new Light(em1Host, 0.75, colExplosion);
      lights.add(em1Light);
      
      // PARTICLES
      
      DAGTransform dag = new DAGTransform(0,0,0, 0, 1,1,1);
      Sprite s = new Sprite(dag, null, 0.5, 0.5, -0.5, -0.5);
      s.setEmissive( fx_streak );
      s.masterTintEmit = colExplosion;
      PVector vel = new PVector(0.2, 0, 0);
      float spin = 0;
      float ageMax = 20;
      Particle p = new Particle(dag, s, vel, spin, ageMax);
      p.streak = true;
      p.aimAlongMotion = true;
      p.disperse = false;
      for(int i = 0;  i < 2;  i++)
        em1.addTemplate(p);
      
      // Puffs
      PVector puffVel = new PVector(0.04, 0, 0);
      float puffSpin = 0.04;
      float puffDisperseSize = 12.0;
      float puffAgeMax = 30;
      PVector pr = new PVector(0.25, 0.25);
      color puffTint = color(colExplosion, 64);
      
      // Puff 1
      dag = new DAGTransform(0,0,0, 0, 1,1,1);
      s = new Sprite(dag, fx_puff1, pr.x, pr.y, -0.5,-0.5);
      s.setNormal(fx_puff1norm);
      s.setEmissive(fx_puff1);
      s.masterTintEmit = puffTint;
      p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
      p.disperseSize = puffDisperseSize;
      p.fadeEmit = Particle.FADE_SQRT;
      p.fadeDiff = Particle.FADE_CUBEROOT;
      p.fadeNorm = Particle.FADE_CUBEROOT;
      em1.addTemplate(p);
      
      // Puff 2
      dag = new DAGTransform(0,0,0, 0, 1,1,1);
      s = new Sprite(dag, fx_puff1, pr.x, pr.y, -0.5,-0.5);
      s.setNormal(fx_puff1norm);
      s.setEmissive(fx_puff2);
      s.masterTintEmit = puffTint;
      p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
      p.disperseSize = puffDisperseSize;
      p.fadeEmit = Particle.FADE_SQRT;
      p.fadeDiff = Particle.FADE_CUBEROOT;
      p.fadeNorm = Particle.FADE_CUBEROOT;
      em1.addTemplate(p);
      
      // Puff 3
      dag = new DAGTransform(0,0,0, 0, 1,1,1);
      s = new Sprite(dag, fx_puff1, pr.x, pr.y, -0.5,-0.5);
      s.setNormal(fx_puff1norm);
      s.setEmissive(fx_puff3);
      s.masterTintEmit = puffTint;
      p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
      p.disperseSize = puffDisperseSize;
      p.fadeEmit = Particle.FADE_SQRT;
      p.fadeDiff = Particle.FADE_CUBEROOT;
      p.fadeNorm = Particle.FADE_CUBEROOT;
      em1.addTemplate(p);
    }
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsMissile
  
  
  public void configureAsBulletA()
  // A cold bullet
  {
    configureAsBullet( color(127,255,191,255) );
  }
  // configureAsBulletA
  
  
  public void configureAsBulletB()
  // A warm bullet
  {
    configureAsBullet( color(255,191,127,255) );
  }
  // configureAsBulletB
  
  
  public void configureAsBullet(color col)
  {
    // Set bullet behaviour
    navMode = NAV_MODE_BULLET;
    maxVel = 1.0;
    maxTurn = 0.0;
    thrust = 0;
    turnThrust = 0;
    radius = 0.0;
    rateVel = 2.0;
    drag = 1.0;  // No friction
    brake = 0.0;
    targetable = false;
    hitpointsMax = 0.1;
    explodeTimerInterval = 1.0;
    dismemberTimerInterval = 1.0;
    ageMax = 90;
    wrap = false;
    colExplosion = col;
    
    // Setup explosion templates
    explosionTemplates.clear();
    setupExplosionTemplatesPyrotechnic(colExplosion);
    explosionParticles = 128;
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    // Core beam
    Sprite bulletMain = new Sprite(hull, null, 0.75, 3.0, -0.5,-0.5);
    bulletMain.setEmissive(fx_streak);
    bulletMain.masterTintEmit = colExplosion;
    sprites.add(bulletMain);
    // Highlight, always yellow
    Sprite bulletHighlight = new Sprite(hull, null, 0.5, 3.0, -0.5,-0.5);
    bulletHighlight.setEmissive(fx_streak);
    bulletHighlight.masterTintEmit = color(255,255,192);
    sprites.add(bulletHighlight);
    
    // Core light
    Light bulletGlow = new Light(hull, 0.8, colExplosion);
    lights.add(bulletGlow);
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsBullet
  
  
  public void configureAsDust()
  {
    navMode = NAV_MODE_DRIFT;
    maxVel = 0.01;
    maxTurn = 0.0001;
    thrust = 0.0001;
    turnThrust = 0.00001;
    turnDrag = 0.8;
    drag = 1.0;
    targetable = false;
    invulnerable = true;
    wrap = true;
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    // Setup some graphics
    Sprite s = new Sprite(hull, debris_dust, 50.0, 50.0, -0.5,-0.5);
    s.masterTintDiff = color(255,255);
    sprites.add(s);
    
    // Animate the hull to rotate
    hull.useR = true;
    float rotSpeed = random(-1,1) * 0.001;
    DAGTransform key1 = new DAGTransform(0,0,0, 0.0, 1,1,1);
    DAGTransform key2 = new DAGTransform(0,0,0, rotSpeed, 1,1,1);
    Animator rotAnim = hull.makeAnimator(key1, key2);
    rotAnim.type = Animator.ANIM_LINEAR;
    anim.add(rotAnim);
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsDust
  
  
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
  
  
  private void setupExplosionTemplatesPyroAndDebris(color col)
  {
    for(int i = 0;  i < 32;  i++)
    {    setupExplosionTemplatesPyrotechnic(col);    }
    setupExplosionTemplatesDebris(col);
  }
  // setupExplosionTemplatesPyroAndDebris
  
  
  private void setupExplosionTemplatesPyrotechnic(color tintCol)
  {
    // Does NOT clear the templates - this can be combined with other template queues.
    
    // Streak particle
    DAGTransform dag = new DAGTransform(0,0,0, 0, 1,1,1);
    Sprite s = new Sprite(dag, null, 0.25, 0.25, -0.5, -0.5);
    s.setEmissive(fx_streak);
    s.masterTintEmit = tintCol;
    PVector vel = new PVector(1.2, 0, 0);
    float spin = 0;
    float ageMax = 60;
    Particle p = new Particle(dag, s, vel, spin, ageMax);
    p.streak = true;
    p.aimAlongMotion = true;
    p.disperse = false;
    for(int i = 0;  i < 8;  i++)
    {
      explosionTemplates.add(p);  // Do it several times to get statistical prevalence
    }
    
    // Rays
    float rayScale = 12.0;
    PVector rayVel = new PVector(0,0,0);
    float raySpin = 0.01;
    float rayAgeMax = 20;
    
    // Ray flare 1
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, rayScale,rayScale, -0.5,-0.5);
    s.setEmissive(fx_ray1);
    s.masterTintEmit = tintCol;
    p = new Particle(dag, s, rayVel, raySpin, rayAgeMax);
    explosionTemplates.add(p);
    
    // Ray flare 2
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, rayScale,rayScale, -0.5,-0.5);
    s.setEmissive(fx_ray2);
    s.masterTintEmit = tintCol;
    p = new Particle(dag, s, rayVel, raySpin, rayAgeMax);
    explosionTemplates.add(p);
    
    
    // Puffs
    float puffScale = 1.0;
    PVector puffVel = new PVector(0.6, 0, 0);
    float puffSpin = 0.04;
    float puffAgeMax = 30;
    
    // Puff 1
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, puffScale,puffScale, -0.5,-0.5);
    s.setEmissive(fx_puff1);
    s.masterTintEmit = tintCol;
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    // Puff 2
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, puffScale,puffScale, -0.5,-0.5);
    s.setEmissive(fx_puff2);
    s.masterTintEmit = tintCol;
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    // Puff 3
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, puffScale,puffScale, -0.5,-0.5);
    s.setEmissive(fx_puff3);
    s.masterTintEmit = tintCol;
    p = new Particle(dag, s, puffVel, puffSpin, puffAgeMax);
    explosionTemplates.add(p);
    
    
    // Spatters
    PVector spatVel = new PVector(0.2, 0, 0);
    float spatSpin = 0.0;
    float spatAgeMax = 30;
    
    // Spatter
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 1,1, -0.5,-0.5);
    s.setEmissive(fx_spatter);
    s.masterTintEmit = color(tintCol, 127);
    p = new Particle(dag, s, spatVel, spatSpin, spatAgeMax);
    explosionTemplates.add(p);
    
    // Spatter black
    dag = new DAGTransform(0,0,0, 0, 1,1,1);
    s = new Sprite(dag, null, 1,1, -0.5,-0.5);
    s.setEmissive(fx_spatter);
    s.masterTintEmit = color(0, 255);
    p = new Particle(dag, s, spatVel, spatSpin, spatAgeMax);
    for(int i = 0;  i < 4;  i++)
      explosionTemplates.add(p);
  }
  // setupExplosionTemplatesPyrotechnic
  
  
  public void setupExplosionTemplatesDebris(color col)
  {
    ArrayList assetsDiff = new ArrayList();
    ArrayList assetsNorm = new ArrayList();
    
    // Assemble diffuse assets
    assetsDiff.add(debris_01_diff);    assetsDiff.add(debris_02_diff);
    assetsDiff.add(debris_03_diff);    assetsDiff.add(debris_04_diff);
    assetsDiff.add(debris_05_diff);    assetsDiff.add(debris_06_diff);
    assetsDiff.add(debris_07_diff);    assetsDiff.add(debris_08_diff);
    assetsDiff.add(debris_09_diff);    assetsDiff.add(debris_10_diff);
    assetsDiff.add(debris_11_diff);    assetsDiff.add(debris_12_diff);
    assetsDiff.add(debris_13_diff);    assetsDiff.add(debris_14_diff);
    assetsDiff.add(debris_15_diff);    assetsDiff.add(debris_16_diff);
    assetsDiff.add(debris_17_diff);    assetsDiff.add(debris_18_diff);
    assetsDiff.add(debris_19_diff);    assetsDiff.add(debris_20_diff);
    assetsDiff.add(debris_21_diff);    assetsDiff.add(debris_22_diff);
    assetsDiff.add(debris_23_diff);    assetsDiff.add(debris_24_diff);
    
    // Assemble normal assets
    assetsNorm.add(debris_01_norm);    assetsNorm.add(debris_02_norm);
    assetsNorm.add(debris_03_norm);    assetsNorm.add(debris_04_norm);
    assetsNorm.add(debris_05_norm);    assetsNorm.add(debris_06_norm);
    assetsNorm.add(debris_07_norm);    assetsNorm.add(debris_08_norm);
    assetsNorm.add(debris_09_norm);    assetsNorm.add(debris_10_norm);
    assetsNorm.add(debris_11_norm);    assetsNorm.add(debris_12_norm);
    assetsNorm.add(debris_13_norm);    assetsNorm.add(debris_14_norm);
    assetsNorm.add(debris_15_norm);    assetsNorm.add(debris_16_norm);
    assetsNorm.add(debris_17_norm);    assetsNorm.add(debris_18_norm);
    assetsNorm.add(debris_19_norm);    assetsNorm.add(debris_20_norm);
    assetsNorm.add(debris_21_norm);    assetsNorm.add(debris_22_norm);
    assetsNorm.add(debris_23_norm);    assetsNorm.add(debris_24_norm);
    
    // Set parameters
    PVector pVel = new PVector(0.2, 0.0,0.0);
    float pSpin = 0.02;
    float pAgeMax = 900;
    
    // Make sprites
    Iterator iDiff = assetsDiff.iterator();
    Iterator iNorm = assetsNorm.iterator();
    while( iDiff.hasNext() )
    {
      PImage diff = (PImage) iDiff.next();
      PImage norm = (PImage) iNorm.next();
      float res = diff.width / 32.0;
      Sprite s = new Sprite(null, diff, res,res, -0.5,-0.5);
      s.setNormal(norm);
      s.setSpecular(diff);
      Particle p = new Particle(null, s, pVel, pSpin, pAgeMax);
      p.disperseSize = -0.5;
      p.fadeDiff = Particle.FADE_CUBEROOT;
      p.fadeNorm = Particle.FADE_NIL;
      p.fadeSpec = Particle.FADE_CUBEROOT;
      explosionTemplates.add(p);
    }
  }
  // setupExplosionTemplatesDebris
  
  
  public DAGTransform getRoot()
  {  return( root );  }
  
  public ArrayList getFragments()
  {  return( fragments );  }
  
  public void setExternalVector(PVector v)
  {  externalVector = v;  }
}
// Ship
