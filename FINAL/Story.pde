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
  boolean recording;
  
  // Event manager
  ArrayList storyEvents;
  
  // Event codes
  public static final int START_RECORDING = 901;
  public static final int PROGRAM_END = 999;
  
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
      case START_RECORDING:
        cmd_start_recording();
        break;
      case PROGRAM_END:
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
  
  
  
  void setupStory()
  // Script the sequence of events
  {
    // Do recording
    //makeEvent(0, START_RECORDING);
    
    // Termination
    //makeEvent(3600, PROGRAM_END);
  }
  // setupStory
}
// Story
