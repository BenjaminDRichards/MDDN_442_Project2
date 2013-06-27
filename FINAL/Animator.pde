class Animator
// Manages procedural animations, whether one-off or continuous.
{
  public boolean pleaseRemove;   // Used to signal animation completion or removal
  private DAGTransform target;   // Subject of animation
  private DAGTransform key1, key2;  // Animation parameters
  private int type;              // Index of animation type
  private float period;          // Animation length (in ticks)
  private float phase;           // Animation completion, in range 0 to 1.
  private float delay;           // Animation offset, useful for cycles
  
  private boolean slider;        // Slider animators don't update on ticks
  
  public static final int ANIM_OSCILLATE = 1;
  public static final int ANIM_TWEEN_LERP = 2;
  public static final int ANIM_TWEEN_SMOOTH = 3;
  public static final int ANIM_TWEEN_FLOP = 4;
  public static final int ANIM_TWEEN_FLOP_OUT = 5;
  public static final int ANIM_NOISE = 6;
  public static final int ANIM_CONSTANT = 7;
  public static final int ANIM_LINEAR = 8;
  
  
  Animator(DAGTransform target, DAGTransform key1, DAGTransform key2, int type, float period)
  {
    this.target = target;
    this.key1 = key1;
    this.key2 = key2;
    this.type = type;
    this.period = period;
    
    delay = 0;
    pleaseRemove = false;
    slider = false;
  }
  
  
  public void run(float tick)
  // Call once per frame to advance simulation
  {
    if(!slider)
    {
      float phaseIncrease = tick / (float) period;
      phase += phaseIncrease;
    }
    
    doAnimation();
  }
  // run
  
  
  public void useSlider(boolean b)
  {
    slider = b;
  }
  // useSlider
  
  
  public void setSlider(float s)
  // Sets the slider, clamped between 1 and 0
  {
    phase = constrain(s, 0, 1);
  }
  // setSlider
  
  
  public void slide(float s)
  // Adjusts the slider
  {
    setSlider(phase + s);
  }
  // slide
  
  
  private void doAnimation()
  // Find the correct animation and execute it
  // This is all based around interpolating between the two key nodes
  {
    float amt = phase - delay;
    amt = max(amt, 0.0);      // No values under 0 are permitted
    
    switch(type)
    {
      case ANIM_OSCILLATE:
        amt = 0.5 + 0.5 * sin( amt * TWO_PI );
        // Does not terminate
        break;
      case ANIM_TWEEN_LERP:
        // amt = amt;
        checkTermination();
        break;
      case ANIM_TWEEN_SMOOTH:
        // 3x^2-2x^3 eased tween
        amt = 3 * pow(amt, 2) - 2 * pow(amt, 3);
        checkTermination();
        break;
      case ANIM_TWEEN_FLOP:
        // As ANIM_TWEEN_SMOOTH, but with anticipation and follow-through.
        amt = computeFlopAmount(amt);
        checkTermination();
        break;
      case ANIM_TWEEN_FLOP_OUT:
        amt = computeFlopOutAmount(amt);
        checkTermination();
        break;
      case ANIM_NOISE:
        amt = noise(amt * 0.03);
        // Does not terminate
        break;
      case ANIM_CONSTANT:
        amt = 0.0;
        // Does not terminate
        break;
      case ANIM_LINEAR:
        //amt = amt;
        // Does not terminate
        break;
      default:
        break;
    }
    
    // Position
    if(key1.usePX  ||  key1.usePY  ||  key1.usePZ)
    {
      PVector lerpPos = PVector.lerp( key1.getUsedPosition(), key2.getUsedPosition(), amt );
      PVector newPos = key1.useWorldSpace  ?  target.getWorldPosition()  :  target.getLocalPosition();
      if(key1.usePX)  newPos.set(lerpPos.x, newPos.y, newPos.z);
      if(key1.usePY)  newPos.set(newPos.x, lerpPos.y, newPos.z);
      if(key1.usePZ)  newPos.set(newPos.x, newPos.y, lerpPos.z);
      if(key1.useWorldSpace)  target.setWorldPosition(newPos.x, newPos.y, newPos.z);
            else              target.setLocalPosition(newPos.x, newPos.y, newPos.z);
    }
    
    // Rotation
    // Note: There is no bounding, you can have multiple turns
    if(key1.useR)
    {
      float lerpR = lerp( key1.getUsedRotation(), key2.getUsedRotation(), amt );
      if(key1.useWorldSpace)  target.setWorldRotation(lerpR);
            else              target.setLocalRotation(lerpR);
    }
    
    // Scale
    if(key1.useSX  ||  key1.useSY  ||  key1.useSZ)
    {
      PVector lerpScale = PVector.lerp( key1.getUsedScale(), key2.getUsedScale(), amt );
      PVector newScale = key1.useWorldSpace  ?  target.getWorldScale()  :  target.getLocalScale();
      if(key1.useSX)  newScale.set(lerpScale.x, newScale.y, newScale.z);
      if(key1.useSY)  newScale.set(newScale.x, lerpScale.y, newScale.z);
      if(key1.useSZ)  newScale.set(newScale.x, newScale.y, lerpScale.z);
      if(key1.useWorldSpace)  target.setWorldScale(newScale.x, newScale.y, newScale.z);
            else              target.setLocalScale(newScale.x, newScale.y, newScale.z);
    }
  }
  // doAnimation
  
  
  private void checkTermination()
  // Flag for removal if animation is complete
  {
    if( 1.0 <= phase - delay    &&    !slider )
    {
      pleaseRemove = true;
    }
  }
  // checkTermination
  
  
  private float computeFlopAmount(float n)
  // A floppy tween with anticipation and recovery
  {
    float amt = 0;
    if(n < 0.25)
    {
      // Anticipation
      float x = n * 4;
      amt = -0.25 * (3 * pow(x, 2) - 2 * pow(x, 3));
    }
    else if(n < 0.75)
    {
      // Action
      float x = (n - 0.25) * 2;
      amt = 1.5 * (3 * pow(x, 2) - 2 * pow(x, 3)) - 0.25;
    }
    else
    {
      // Recovery
      float x = (n - 0.75) * 4;
      amt = 1.25 - 0.25 * (3 * pow(x, 2) - 2 * pow(x, 3));
    }
    return( amt );
    
    // (3x^2-2x^3) - (x/(1+x)) gives rather nice anticipation but only reaches 0.5
  }
  // computeFlopAmount
  
  
  private float computeFlopOutAmount(float n)
  // A floppy tween with no anticipation, just recovery
  {
    float amt = 0;
    if(n < 0.75)
    {
      // Action
      float x = n / 0.75;
      amt = 1.25 * (3 * pow(x, 2) - 2 * pow(x, 3));
    }
    else
    {
      // Recovery
      float x = (n - 0.75) * 4;
      amt = 1.25 - 0.25 * (3 * pow(x, 2) - 2 * pow(x, 3));
    }
    return( amt );
  }
  // computeFlopOutAmount
  
  
  public void setPeriod(float p)  {  this.period = p;  }
  
  
  public void setType(int type)
  {
    this.type = type;
  }
  
  
  public void setDelay(float delay)
  // Sets the delay, which is defined in periods, not frames or seconds - it can vary
  {
    this.delay = delay;
  }
  // setOffset
}
// Animator
