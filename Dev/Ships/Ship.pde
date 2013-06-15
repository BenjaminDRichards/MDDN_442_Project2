import java.util.*;


class Ship
{
  // Structural data
  private DAGTransform root;
  private ArrayList sprites;
  
  // Navigational data
  private DAGTransform target;
  private float rateVel, rateTurn;      // Momentum figures
  private float maxVel, maxTurn;
  private float destinationRadius;
  private float thrust, drag, brake;
  private float turnThrust, turnDrag, turnBrake;
  
  // Rates of change
  float roc_turnLeft, roc_turnRight, roc_moveFore, roc_moveBack, roc_moveLeft, roc_moveRight;
  
  
  Ship(PVector pos, PVector targetPos)
  {
    root = new DAGTransform(pos.x, pos.y, pos.z,  0,  1,1,1);
    target = new DAGTransform(targetPos.x, targetPos.y, targetPos.z,  0,  1,1,1);
    
    // Assets
    sprites = new ArrayList();
    
    // Navigation parameters
    rateVel = 0;
    rateTurn = 0;
    maxVel = 0.1;
    maxTurn = 0.02;
    destinationRadius = 5;
    thrust = 0.001;
    drag = 0.999;
    brake = thrust;
    turnThrust = 0.0005;
    turnDrag = 0.97;
    turnBrake = turnThrust;
  }
  
  
  public void run(float tick)
  // Perform animation/simulation/navigation
  {
    // Handle target
    // Navigate towards target
    doNavigation(tick);
    
    // Compute rates of change
    
    // Apply rates of change to animation sliders
    
    // Check weapons systems
  }
  // run
  
  
  
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
      // Temp diagnostic
      fill(255,0,0);
      
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
        rateTurn += turnThrust;
      }
      if(sepAngle < rr)
      {
        // Turn right
        rateTurn -= turnThrust;
      }
      
      // Accelerate towards target
      rateVel += thrust;
    }
    
    // When inside region, slow down and match heading
    else
    {
      // Temp diagnostic
      fill(0,0,255);
      
      rateVel  = max( rateVel - brake,  0.0 );
    }
    
    // Apply navigational physics
    rateTurn = constrain(rateTurn, -maxTurn, maxTurn) * turnDrag;
    root.rotate(rateTurn);
    rateVel = constrain(rateVel, -maxVel, maxVel) * drag;
    PVector thrustVector = PVector.fromAngle( root.getWorldRotation() );
    thrustVector.mult(rateVel);
    root.moveLocal(thrustVector.x, thrustVector.y, thrustVector.z);
    
    
    // Temp diagnosis
    pushMatrix();
    translate(rpos.x, rpos.y);
    rotate( root.getWorldRotation() );
    ellipse(0,0, 5,3);
    popMatrix();
  }
  // doNavigation
  
  
  private void doNavTargeting()
  // Figure out where the ship is going
  {
    // Simple mouse chaser
    target.setWorldPosition(screenMouseX(), screenMouseY(), 0);
  }
  // doNavTargeting
}
// Ship
