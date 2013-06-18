import java.util.*;


class Ship
{
  // Structural data
  private DAGTransform root;      // Root transform
  private ArrayList sprites;      // Sprites for rendering
  
  // Navigational data
  private int navMode;
  private DAGTransform target;
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
  
  // Animation data
  ArrayList animTurnLeft, animTurnRight, animThrust, anim;
  ArrayList particles;
  
  // Destructural data
  private ArrayList breakpoints;  // Children of root that might break away during an explosion
  private ArrayList fragments;    // Pieces that break away from root
  private boolean exploding;
  public boolean pleaseRemove;
  private float explodeTimer, explodeTimerInterval;
  private float dismemberTimer, dismemberTimerInterval;
  
  // Military data
  int team;
  float age, ageMax;
  
  
  Ship(PVector pos, PVector targetPos, int navMode, ShipManager shipManager)
  {
    root = new DAGTransform(pos.x, pos.y, pos.z,  0,  1,1,1);
    target = new DAGTransform(targetPos.x, targetPos.y, targetPos.z,  0,  1,1,1);
    this.shipManager = shipManager;
    
    // Assets and animation
    sprites = new ArrayList();
    animTurnLeft = new ArrayList();
    animTurnRight = new ArrayList();
    animThrust = new ArrayList();
    anim = new ArrayList();
    particles = new ArrayList();
    
    // Navigation parameters
    this.navMode = navMode;
    rateVel = 0;
    rateTurn = 0;
    maxVel = 0.1;
    maxTurn = 0.02;
    radius = 10;
    destinationRadius = 5;
    thrust = 0.001;
    drag = 0.995;
    brake = thrust;
    turnThrust = 0.0005;
    turnDrag = 0.98;
    turnBrake = turnThrust;
    wrap = true;
    float margin = 1.05;
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
    
    // Military data
    team = 0;  // Team 0 is essentially targets
    age = 0;
    ageMax = 180;  // This is only used for missiles
    
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
    
    // Check weapons systems
    
    // Check explosions
    if(exploding)
      doExploding(tick);
    
    // Do aging
    age += tick;
  }
  // run
  
  
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
    float tr = target.getWorldRotation();
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
      case NAV_MODE_HOMING:
        doNavTargetingHoming();
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
    target.moveLocal(radius * 3.0, 0, 0);
    target.setParentToWorld();
    // Introduce some wiggle
    float r = 1.0;
    target.moveLocal( random(-r,r), random(-r,r), random(-r,r) );
    // Look for nearby obstacles
    float detectRadius = radius * 4.0;
    Ship ship = shipManager.getNearestShipTo( target.getWorldPosition() );
    if(ship != null)
    {
      PVector vecBetween = PVector.sub( root.getWorldPosition(),  ship.getRoot().getWorldPosition() );
      if( vecBetween.mag() < detectRadius)
      {
        target.moveWorld(vecBetween.x, vecBetween.y, vecBetween.z);
      }
    }
  }
  // doNavTargetingAvoid
  
  
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
        enemy.startExploding();
      }
    }
    // Time out
    if(ageMax < age)
    {
     startExploding();
    }
  }
  // doNavTargetingHoming
  
  
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
  
  
  public void startExploding()
  // Initiate a sequence of events that eventually destroy the ship
  {
    // Set the ship on its course: disable steering
    thrust = 0;
    brake = 0;
    turnThrust = 0;
    animTurnLeft.clear();
    animTurnRight.clear();
    animThrust.clear();
    
    // Enable explosion systems
    exploding = true;
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
      float tumble = random(-0.02, 0.02);
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
  }
  // breakOff
  
  
  private void makeExplosion(PVector pos)
  // Emit some particles at position pos
  {
    int pop = 128;
    for(int i = 0;  i < pop;  i++)
    {
      DAGTransform dag = new DAGTransform(pos.x, pos.y, pos.z,  0,  1,1,1);
      PVector vel = PVector.fromAngle( random(TWO_PI) );
      float velScalar = 0.4 * pow( random(1), 2 );
      vel.mult( velScalar );
      float ageMax = 60 * pow( random(1), 3 );
      ParticleStreak ps = new ParticleStreak(dag, vel, 0, ageMax, 1.0);
      particles.add(ps);
    }
  }
  // makeExplosion
  
  
  
  public void configureAsPreyA()
  // Configures the ship as a Prey-A model
  {
    // Create the hull
    // This will later be rotated, but is for now held on the origin
    // This makes further construction far more logical
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    sprites.add( new Sprite(hull, testShipSprite, 2,2, -0.5,-0.5) );
    
    // Create left turn panel
    DAGTransform leftThruster = new DAGTransform(-1, -2, 0, 0, 1,1,1);
    leftThruster.setParent(hull);
    /* Setup some graphics */
    sprites.add( new Sprite(leftThruster, testShipSprite, 2,2, -0.5,-0.5) );
    // Set sliders for left turn panel
    leftThruster.useR = true;
    DAGTransform leftThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform leftThruster_key2 = new DAGTransform(0,0,0, -QUARTER_PI * 0.5, 1,1,1);
    Animator leftThruster_anim = leftThruster.makeSlider(leftThruster_key1, leftThruster_key2);
    // Register slider to internal controllers
    animTurnRight.add(leftThruster_anim);
    breakpoints.add(leftThruster);
    
    // Create right turn panel
    DAGTransform rightThruster = new DAGTransform(1, -2, 0, 0, 1,1,1);
    rightThruster.setParent(hull);
    /* Setup some graphics */
    sprites.add( new Sprite(rightThruster, testShipSprite, 2,2, -0.5,-0.5) );
    // Set sliders for right turn panel
    rightThruster.useR = true;
    DAGTransform rightThruster_key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    DAGTransform rightThruster_key2 = new DAGTransform(0,0,0, QUARTER_PI * 0.5, 1,1,1);
    Animator rightThruster_anim = rightThruster.makeSlider(rightThruster_key1, rightThruster_key2);
    // Register slider to internal controllers
    animTurnLeft.add(rightThruster_anim);
    breakpoints.add(rightThruster);
    
    // FINALISE
    boltToRoot(hull);
  }
  // configureAsPreyA
  
  
  public void configureAsMissileA()
  // A basic missile, with missile behaviours
  {
    // Set homing behaviour
    navMode = NAV_MODE_HOMING;
    maxVel = 0.4;
    maxTurn = 0.03;
    thrust = 0.01;
    radius = 3.0;
    destinationRadius = 1.0;
    explodeTimerInterval = 1.0;
    dismemberTimerInterval = 1.0;
    
    // Create geometry
    DAGTransform hull = new DAGTransform(0,0,0, 0, 1,1,1);
    /* Setup some graphics */
    sprites.add( new Sprite(hull, testShipSprite, 2,2, -0.5,-0.5) );
    
    // Finalise
    boltToRoot(hull);
  }
  // configureAsMissileA
  
  
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
  
  
  public DAGTransform getRoot()
  {  return( root );  }
  
  public ArrayList getFragments()
  {  return( fragments );  }
}
// Ship
