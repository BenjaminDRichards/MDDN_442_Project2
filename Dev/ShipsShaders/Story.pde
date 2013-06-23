import java.util.*;

class Story
/*

Control system for the events that occur.

A way to hide all the complex setup from the main program,
then schedule interesting things to happen.

Includes time management.

*/
{
  // Scene
  ArrayList sprites;
  boolean recording;
  
  // Event manager
  ArrayList storyEvents;
  
  // Time parameters
  int timeMode;      // 0 = realtime, 1 = render every frame
  float lastTickCount, thisTickCount;
  float idealFrameRate;
  float tick;
  float tickTotal;
  boolean pause;
  
  float TIMESKIP = 1;           // Number of frames to advance per iteration
                                //  Don't set to 0!
  float START_OFFSET = 0;       // Fast-forward the beginning
  
  // Asset tracking
  
  
  // Graphics
  
  
  Story()
  {
    storyEvents = new ArrayList();
    
    // Setup scene
    sprites = new ArrayList();
    recording = false;
    
    // Setup story
    setupStory();
    
    // Setup time
    timeMode = 0;
    idealFrameRate = 60;
    thisTickCount = 0.0;
    lastTickCount = -1.0;
    tick = 1;
    tickTotal = START_OFFSET;
    pause = false;
  }
  
  
  
  void run()
  // Execute decisions and animation
  {
    manageTime();
    
    // Check story events
    Iterator i = storyEvents.iterator();
    while( i.hasNext() )
    {
      StoryEvent se = (StoryEvent) i.next();
      if( se.isTriggered(tickTotal) )
      {
        // Update time and check if time trigger occurs
        command(se.commandCode);
        i.remove();
      }
    }
    
    // Render graphics
    render();
  }
  // run
  
  
  void manageTime()
  {
    if(timeMode == 0)
    {
      // Use realtime tick
      lastTickCount = thisTickCount;
      thisTickCount = millis() * idealFrameRate / 1000.0;
      tick = thisTickCount - lastTickCount;
    }
    else if(timeMode == 1)
    {
      // Use unitary tick
      thisTickCount += TIMESKIP;
      lastTickCount += TIMESKIP;
      tick = TIMESKIP;
    }
    
    // Track time spent running
    tickTotal += tick;
    // Give it some time to settle down
    if(frameCount < 4)  tickTotal = frameCount + START_OFFSET;
  }
  // manageTime
  
  
  void render(PGraphics pg)
  {
    // Background
    renderBackground(pg);
    
    // Render sprites
    pg.pushStyle();
    pg.tint(0);
    Iterator iSpr = sprites.iterator();
    while( iSpr.hasNext() )
    {
      Sprite sprite = (Sprite) iSpr.next();
      sprite.render(pg);
    }
    pg.popStyle();
    
    
    // Recording
    if(recording)
    {
      String filename = "render" + nf(frameCount, 6) + ".png";
      save("renders/" + filename);
    }
  }
  // render
  
  void render()
  // Renders to g (default graphics)
  {
    render(g);
  }
  // render
  
  
  private void renderBackground(PGraphics pg)
  // Paints the backdrop
  {
    pg.background(64);
  }
  // renderBackground
  
  
  
  void makeEvent(float time, int code)
  // Make and register story event
  {
    StoryEvent se = new StoryEvent(time, code);
    storyEvents.add(se);
  }
  // makeEvent
  
  
  
  void command(int code)
  // Runs a predefined command code
  {
    println("Code " + code + " triggered at " + tickTotal);
    
    switch(code)
    {
      case 901:
        cmd_start_recording();
        break;
      case 999:
        cmd_program_end();
        break;
      default:
        break;
    }
  }
  // command
  
  
  void cmd_start_recording()
  // CODE 901
  // Sets time to no-skip and starts recording
  {
    timeMode = 1;
    recording = true;
  }
  // cmd_start_recording
  
  
  void cmd_program_end()
  // CODE 999
  // Ends the program at the appointed time
  {
    exit();
  }
  // cmd_program_end
  
  
  public ArrayList getSprites()
  {
    return( sprites );
  }
  // getSprites
  
  
  
  void setupStory()
  // Script the sequence of events
  {
    // Do recording
    //makeEvent(0, 901);
    
    // Termination
    //makeEvent(3600, 999);
  }
  // setupStory
  
  
  public void makeSlider(DAGTransform adagr, DAGTransform key1, DAGTransform key2)
  // Creates a slider for "adagr", between key1 and key2
  {
    // Comply flags from adagr
    key1.useWorldSpace = adagr.useWorldSpace;
    key1.usePX = adagr.usePX;    key1.usePY = adagr.usePY;    key1.usePZ = adagr.usePZ;
    key1.useR = adagr.useR;
    key1.useSX = adagr.useSX;    key1.useSY = adagr.useSY;    key1.useSZ = adagr.useSZ;
    key2.useWorldSpace = adagr.useWorldSpace;
    key2.usePX = adagr.usePX;    key2.usePY = adagr.usePY;    key2.usePZ = adagr.usePZ;
    key2.useR = adagr.useR;
    key2.useSX = adagr.useSX;    key2.useSY = adagr.useSY;    key2.useSZ = adagr.useSZ;
    
    // Create slider
    Animator slider = new Animator(adagr, key1, key2, Animator.ANIM_TWEEN_SMOOTH, 1);
    slider.useSlider(true);
    /**/
    // Connect this to some control?
    //slider.setSlider(masterSlider);
    /**/
    slider.run(0);
    /*
    // Register slider
    sliders.add(slider);
    */
  }
  // makeSlider
  
  
  public void makeZeroSlider(DAGTransform adagr)
  // Creates keys and registers sliders to turn "adagr" on or off smoothly
  // "Off" here refers to origin values (0,0,0, 0, 1,1,1)
  {
    // Create zero key
    DAGTransform key1 = new DAGTransform(0,0,0, 0, 1,1,1);
    // Create max key
    PVector pos = adagr.getUsedPosition();
    float r = adagr.getUsedRotation();
    PVector scale = adagr.getUsedScale();
    DAGTransform key2 = new DAGTransform(pos.x, pos.y, pos.z,  r,  scale.x, scale.y, scale.z);
    // Make slider
    makeSlider(adagr, key1, key2);
  }
  // makeZeroSlider
}
// Story
