/*
  Ship navigation and animation program
  
  This code generates and controls some ships that fly around.
  They use DAG nodes for sub-animation and positioning.
*/


import java.util.*;
import processing.video.*;


Story story;

ShipManager sceneShipManager;
Ship playerShip;

RenderManager renderManager;

Capture cam;
BackgroundLearner bgLearn;
MotionCursor motionCursor;
boolean diagnoseBuffers;

PImage lightStencil;
PGraphics testShipSprite;
PImage tex_diff, tex_norm, tex_cloakNorm;


void setup()
{
  size(1280, 720, P2D);
  
  
  // Setup story
  story = new Story();
  
  
  // Setup renderer
  renderManager = new RenderManager(g);
  
  
  // Setup camera
  String[] cameras = Capture.list();
  if (cameras.length == 0)
  {
    println("There are no cameras available for capture.");
    exit();
  }
  // Initialise camera from list
  // My list has a 640*480 30fps feed at position 1
  //cam = new Capture(this, cameras[1]);
  // But for generic lists I'll be more specific:
  cam = new Capture(this, 320, 240, 30); 
  cam.start();
  // Make certain the camera has begun
  // This is necessary for the BackgroundLearner to work
  while( !cam.available() )
  {
    killTime(1.0);
  }
  
  // Setup camera systems
  bgLearn = new BackgroundLearner(cam);
  motionCursor = new MotionCursor();
  diagnoseBuffers = true;
  
  // Load resources
  lightStencil = loadImage("lightStencil16.png");
  
  tex_diff = loadImage("ship2_series7_diff_512.png");
  tex_norm = loadImage("ship2_series7_norm_512.png");
  tex_cloakNorm = loadImage("ship2_series7_512_blurNormal.png");
  
  
  
  
  
  
  // Test ship sprite
  testShipSprite = createGraphics(64,64,P2D);
  testShipSprite.beginDraw();
  //testShipSprite.background(255,0,0);
  testShipSprite.loadPixels();
  for(int i = 0;  i < testShipSprite.pixels.length;  i++)
  {
    float x = i % testShipSprite.width;
    float y = floor(i / testShipSprite.width);
    x = x / (float) testShipSprite.width;
    y = y / (float) testShipSprite.height;
    testShipSprite.pixels[i] = color(255 * x, 255 * y, 0);
  }
  testShipSprite.updatePixels();
  testShipSprite.endDraw();
  
  // Test ship code
  sceneShipManager = new ShipManager();
  for(int i = 0;  i < 48;  i++)
  {
    spawnShipPreyA();
  }
  {
    // Test gunboat
    PVector pos = new PVector(0, 50, 0);
    PVector targetPos = pos.get();
    targetPos.add( new PVector(0, 1, 0) );
    Ship gunboat = sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_GUNBOAT, 1);
    
    playerShip = gunboat;
  }
}
// setup





void draw()
{
  /*
  CONTROL
  */
  
  // Handle camera input
  cam.read();
  bgLearn.run();
  motionCursor.run( bgLearn.getHeatIso() );
  motionCursor.pipHeight = bgLearn.pipHeight;
  // Control player ship
  PVector playerTarget = motionCursor.getCursorNormalized();
  playerShip.setExternalVector( new PVector(toPercentX(playerTarget.x * width), toPercentY(playerTarget.y * height), 0.0) );
  
  
  /*
  SIMULATE AND RENDER
  */
  
  // Manage story
  story.run();
  
  // Manage ships
  sceneShipManager.run(story.tick);
  sceneShipManager.render(renderManager);
  
  // Temporary warp test
  DAGTransform warpDag = new DAGTransform(25, 50, 0,  frameCount * 0.02,  1,1,1);
  Sprite warpSprite = new Sprite(warpDag, null, 50, 50, -0.5, -0.5);
  warpSprite.setWarp(tex_cloakNorm);
  warpSprite.alphaWarp = 1.0;
  renderManager.addSprite(warpSprite);
  
  // Perform final render
  renderManager.render();
  
  
  
  /*
  UI DRAW
  */
  
  // Visualise camera systems
  if(diagnoseBuffers)
  {
    bgLearn.diagnoseBuffers();
    motionCursor.diagnose();
  }
  
  // Draw motion cursor tracking data
  motionCursor.renderMoVis();
  
  
  
  /*
  Diagnostics
  */
  
  if(frameCount % 60 == 0)  println("FPS " + frameRate);
}
// draw


void mouseReleased()
{
  /*
  // Convert mouse coordinates to screen space
  float mx = screenMouseX();
  float my = screenMouseY();
  
  if(mouseButton == LEFT)
  {
    PVector pos = new PVector(mx, my, 0);
    PVector targetPos = pos.get();
    targetPos.add( PVector.random3D() );
    Ship s = sceneShipManager.makeShip( pos, targetPos, ShipManager.MODEL_MISSILE_A, 1);
    s.team = 1;
  }
  
  if(mouseButton == RIGHT)
  {
    PVector pos = new PVector(mx, my, 0);
    PVector targetPos = pos.get();
    targetPos.add( PVector.random3D() );
    Ship s = sceneShipManager.makeShip( pos, targetPos, ShipManager.MODEL_BULLET_A, 1);
    s.team = 1;
  }
  */
}
// mouseReleased


void keyPressed()
{
  if( key == 'S'  ||  key == 's' )  {  spawnShipPreyA();  }
  
  if( key == '~'  ||  key == '`' )  {  diagnoseBuffers = !diagnoseBuffers;  }
  
  if( key == 'L'  ||  key == 'l' )  {  bgLearn.learnInstant();  }
  
  if( key == '1' )       {  bgLearn.slideCanvasBlur(0.001);  }
  else if( key == '!' )  {  bgLearn.slideCanvasBlur(-0.001);  }
  
  if( key == '2' )       {  bgLearn.slideLearnRate(1.1);  }
  else if( key == '@' )  {  bgLearn.slideLearnRate(1.0 / 1.1);  }
  
  if( key == '3' )       {  bgLearn.slideBackgroundThreshold(0.01);  }
  else if( key == '#' )  {  bgLearn.slideBackgroundThreshold(-0.01);  }
  
  if( key == '4' )       {  bgLearn.slideHeatFade(1.0);  }
  else if( key == '$' )  {  bgLearn.slideHeatFade(-1.0);  }
  
  if( key == '5' )       {  bgLearn.slideHeatIsoBlur(0.005);  }
  else if( key == '%' )  {  bgLearn.slideHeatIsoBlur(-0.005);  }
  
  // Slide cursor brightness threshold
  if( key == '6' )       {  motionCursor.slideThresholdBrightness(0.01);  }
  else if( key == '^' )  {  motionCursor.slideThresholdBrightness(-0.01);  }
  
  // Slide cursor reliability threshold
  if( key == '7' )       {  motionCursor.slideThresholdReliability(0.001);  }
  else if( key == '&' )  {  motionCursor.slideThresholdReliability(-0.001);  }
}
// keyPressed



float screenMouseX()
// Convert mouseX to screen space
{
  return( toPercentX(mouseX) );
}
// screenMouseX

float screenMouseY()
// Convert mouseY to screen space
{
  return( toPercentY(mouseY) );
}
// screenMouseX

float toPercentX(float x)
{  return( (x - width * 0.5) * 100.0 / (float)height );  }
float toPercentY(float y)
{  return( y * 100.0 / (float) height);  }

float fromPercentX(float x)
{  return( height * x * 0.01 + width * 0.5 );  }
float fromPercentY(float y)
{  return( fromPercent(y) );  }
float fromPercent(float n)
{  return( n * height * 0.01 );  }


void spawnShipPreyA()
{
  PVector pos = new PVector(random(-50,50), random(100), 0);
  PVector targetPos = pos.get();
  targetPos.add( PVector.random3D() );
  sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_PREY_A, 0);
}




void debugDags(ArrayList dags)
// Visualise some dags
{
  noStroke();
  fill(127);
  Iterator i = dags.iterator();
  while( i.hasNext() )
  {
    DAGTransform d = (DAGTransform) i.next();
    pushMatrix();
    translate(d.getWorldPosition().x, d.getWorldPosition().y);
    rotate(d.getWorldRotation());
    scale(d.getWorldScale().x, d.getWorldScale().y);
    rect(-0.5,-0.5, 1,1);
    popMatrix();
  }
}
// debugDags


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
