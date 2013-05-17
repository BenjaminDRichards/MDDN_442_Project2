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
  
  
  // Setup background learner
  bgLearn = new BackgroundLearner(cam);
  
  
  // Setup motion cursor system
  motionCursor = new MotionCursor();
  
  diagnoseBuffers = true;
}


void draw()
{
  // Run camera
  if( cam.available() )
  {
    cam.read();
  }
  
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
    image(bgLearn.getCanvas(), 0, 0);
    image(bgLearn.getBackgroundBuffer(), 0,60);
    image(bgLearn.getForegroundMask(), 0,120);
    image(bgLearn.getForeground(), 0,180);
    image(bgLearn.getHeat(), 0, 240);
    image(bgLearn.getHeatIso(), 0,300);
    image(motionCursor.getSelBuffer(), 80,0);
  }
  
  // Draw motion cursor tracking data
  motionCursor.renderMoVis();
}



void keyPressed()
{
  if( key == 'l'  ||  key == 'L' )
  {
    // "L" means "learn background instantly"
    bgLearn.learnInstant();
  }
}
// keyPressed
