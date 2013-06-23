/*
    Camera blob tracker
    Uses a background learner
*/

import processing.video.*;


Capture cam;
BackgroundLearner bgLearn;
MotionCursor motionCursor;
boolean diagnoseBuffers;


void setup()
{
  size(1024, 768, P2D);
  
  
  // Setup camera
  
  String[] cameras = Capture.list();
  
  if (cameras.length == 0)
  {
    println("There are no cameras available for capture.");
    exit();
  }
  
  // Initialise camera from list
  // My list has a 640*480 30fps feed at position 1, so I'm taking that.
  cam = new Capture(this, cameras[1]);
  cam.start();
  // Make certain the camera has begun
  // This is necessary for the BackgroundLearner to work
  // There was formerly a "trySetupCanvas" method, but it's healthier to call cam.available only once.
  while( !cam.available() )
  {
    killTime(1.0);
  }
  
  
  // Setup background learner
  bgLearn = new BackgroundLearner(cam);
  
  
  // Setup motion cursor system
  motionCursor = new MotionCursor();
  
  diagnoseBuffers = true;
}


void draw()
{
  // Run camera
  cam.read();
  
  // Run learner
  bgLearn.run();
  
  // Run cursor
  motionCursor.run(bgLearn.getHeatIso());
  
  
  
  // Graphics
  
  // Clear
  background(0);
  
  // Draw camera image
  pushStyle();
  //tint(64);
  //image(cam, 0,0, width,height);
  image(bgLearn.getCanvas(), 0,0, width, height);
  popStyle();
  
  // Draw learner
  if(diagnoseBuffers)
  {
    bgLearn.diagnoseBuffers();
    motionCursor.diagnose();
  }
  
  // Draw motion cursor tracking data
  motionCursor.renderMoVis();
  
  
  if(frameCount % 60 == 0)  println("FPS " + frameRate);
}



void keyPressed()
{
  if( key == '~'  ||  key == '`' )
  {
    // Toggle buffer diagnostics
    diagnoseBuffers = !diagnoseBuffers;
  }
  
  if( key == 'L'  ||  key == 'l' )
  {
    // "L" means "learn background instantly"
    bgLearn.learnInstant();
  }
  
  if( key == '1' )
  {
    // Slide up canvas blur
    bgLearn.slideCanvasBlur(0.001);
  }
  else if( key == '!' )
  {
    // Slide down canvas blur
    bgLearn.slideCanvasBlur(-0.001);
  }
  
  if( key == '2' )
  {
    // Slide up learn rate
    bgLearn.slideLearnRate(1.1);
  }
  else if( key == '@' )
  {
    // Slide down learn rate
    bgLearn.slideLearnRate(1.0 / 1.1);
  }
  
  if( key == '3' )
  {
    // Slide up background threshold
    bgLearn.slideBackgroundThreshold(0.01);
  }
  else if( key == '#' )
  {
    // Slide down background threshold
    bgLearn.slideBackgroundThreshold(-0.01);
  }
  
  if( key == '4' )
  {
    // Slide up heat fade
    bgLearn.slideHeatFade(1.0);
  }
  else if( key == '$' )
  {
    // Slide down heat fade
    bgLearn.slideHeatFade(-1.0);
  }
  
  if( key == '5' )
  {
    // Slide up heat fade
    bgLearn.slideHeatIsoBlur(0.005);
  }
  else if( key == '%' )
  {
    // Slide down heat fade
    bgLearn.slideHeatIsoBlur(-0.005);
  }
  
  // Slide cursor brightness threshold
  if( key == '6' )
  {
    motionCursor.slideThresholdBrightness(0.01);
  }
  else if( key == '^' )
  {
    motionCursor.slideThresholdBrightness(-0.01);
  }
  
  // Slide cursor reliability threshold
  if( key == '7' )
  {
    motionCursor.slideThresholdReliability(0.001);
  }
  else if( key == '&' )
  {
    motionCursor.slideThresholdReliability(-0.001);
  }
}
// keyPressed



void killTime(float ms)
// An ad-hoc sort of delay
{
  float start = millis();
  float uselessNumber1 = 0;
  float uselessNumber2 = 1;
  while( millis() - start < ms)
  {
    float newUselessNumber = uselessNumber1 + uselessNumber2;
    uselessNumber1 = uselessNumber2;
    uselessNumber2 = newUselessNumber;
  }
}
// killTime
