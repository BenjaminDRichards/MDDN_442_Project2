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
int MIN_SHIP_COUNT = 16;

RenderManager renderManager;

Capture cam;
BackgroundLearner bgLearn;
MotionCursor motionCursor;
boolean diagnoseBuffers;
color GUI_COLOR = color(255, 192, 64);

ArrayList sceneLights;

PImage lightStencil;
PGraphics testShipSprite;
PImage tex_diff, tex_norm, tex_cloakNorm;
PImage tex_backdrop, tex_warpBackdrop;
PImage fx_shockwave, fx_ray1, fx_ray2, fx_ray1pc, fx_ray2pc;
PImage fx_puff1, fx_puff2, fx_puff3, fx_puff1pc, fx_puff2pc, fx_puff3pc;
PImage fx_spatter, fx_spatterPc, fx_spatterBlack;
PImage fx_streak, fx_streakPC;


void setup()
{
  size(1280, 720, P2D);
  
  
  // Load resources
  lightStencil = loadImage("images/lightStencil16.png");
  
  tex_diff = loadImage("images/ships/ship2_series7/ship2_series7_diff_512.png");
  tex_norm = loadImage("images/ships/ship2_series7/ship2_series7_norm_512.png");
  tex_cloakNorm = loadImage("images/ships/ship2_series7/ship2_series7_512_blurNormal.png");
  tex_backdrop = loadImage("images/starscape.png");
  tex_warpBackdrop = loadImage("images/windowGlass.png");
  fx_shockwave = loadImage("images/effects/shockwave2.png");
  fx_ray1 = loadImage("images/effects/ray1.png");
  fx_ray2 = loadImage("images/effects/ray2.png");
  fx_ray1pc = loadImage("images/effects/ray1pc.png");
  fx_ray2pc = loadImage("images/effects/ray2pc.png");
  fx_puff1 = loadImage("images/effects/puff1.png");
  fx_puff2 = loadImage("images/effects/puff2.png");
  fx_puff3 = loadImage("images/effects/puff3.png");
  fx_puff1pc = loadImage("images/effects/puff1pc.png");
  fx_puff2pc = loadImage("images/effects/puff2pc.png");
  fx_puff3pc = loadImage("images/effects/puff3pc.png");
  fx_spatter = loadImage("images/effects/spatter.png");
  fx_spatterPc = loadImage("images/effects/spatterPc.png");
  fx_spatterBlack = loadImage("images/effects/spatterBlack.png");
  fx_streak = loadImage("images/effects/streak.png");
  fx_streakPC = loadImage("images/effects/streakPC.png");
  
  
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
  diagnoseBuffers = false;
  
  // Setup constant lights
  sceneLights = new ArrayList();
  // Directional lights
  DAGTransform dirLightDag = new DAGTransform(0,0,0, 0, 1,1,1);  // Necessary evil
  Light ldir = new Light(dirLightDag, 0.6, color(192, 222, 255, 255));
  ldir.makeDirectional( new PVector(-0.2, -1, -0.5) );
  sceneLights.add(ldir);
  
  
  
  
  
  // Test ship sprite
  testShipSprite = createGraphics(64,64,P2D);
  testShipSprite.beginDraw();
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
  
  // Ship code
  sceneShipManager = new ShipManager();
  {
    // PLAYER VESSEL
    // Added first, so it's always on the bottom of the stack
    PVector pos = new PVector(0, 50, 0);
    PVector targetPos = pos.get();
    targetPos.add( new PVector(0, 1, 0) );
    Ship gunboat = sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_GUNBOAT, 1);
    
    playerShip = gunboat;
  }
  for(int i = 0;  i < 16;  i++)
  {
    spawnShipPreyA();
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
  
  // Manage scene lights
  Iterator iLights = sceneLights.iterator();
  while( iLights.hasNext() )
  {
    Light l = (Light) iLights.next();
    renderManager.addLight(l);
  }
  
  // Manage ships
  sceneShipManager.run(story.tick);
  sceneShipManager.render(renderManager);
  if(sceneShipManager.ships.size() < MIN_SHIP_COUNT)
  {
    spawnShipPreyA();
  }
  
  /*
  // Temporary warp test
  DAGTransform warpDag = new DAGTransform(25, 50, 0,  story.tickTotal * 0.01,  1,1,1);
  Sprite warpSprite = new Sprite(warpDag, null, 50, 50, -0.5, -0.5);
  warpSprite.setWarp(tex_cloakNorm);
  warpSprite.alphaWarp = 0.5 + 0.5 * sin(story.tickTotal * 0.05);
  renderManager.addSprite(warpSprite);
  // Second overlapping sprite
  warpDag = new DAGTransform(15, 50, 0,  story.tickTotal * -0.01,  1,1,1);
  warpSprite = new Sprite(warpDag, null, 50, 50, -0.5, -0.5);
  warpSprite.setWarp(tex_cloakNorm);
  warpSprite.alphaWarp = 1.0;
  renderManager.addSprite(warpSprite);
  */
  
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
  
  
  // Draw excitement meters and HUD
  drawHUD();
  
  
  
  /*
  Diagnostics
  */
  //background(255);
  //image(renderManager.bNormal, 0,0, width, height);
  
  if(frameCount % 60 == 0)
  {
    //println("FPS " + frameRate);
    
    //println("Cloak: " + playerShip.cloaked + ", cloakActivation " + playerShip.cloakActivation
    //    + ", excitement " + playerShip.excitement);
  }
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
  
  if( key == '5' )       {  bgLearn.slideHeatIsoBlur(0.001);  }
  else if( key == '%' )  {  bgLearn.slideHeatIsoBlur(-0.001);  }
  
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
  PVector pos = new PVector(random(-60,60), -10, 0);
  PVector targetPos = pos.get();
  targetPos.add( PVector.random3D() );
  sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_PREY_A, 0);
}


void drawHUD()
{
  // Draw motion cursor tracking data
  motionCursor.renderMoVis();
  
  // Draw activity meters
  pushMatrix();
  pushStyle();
  noStroke();
  fill(GUI_COLOR, 127);
  translate(width * 0.5, height * 0.9);
  if(0 < playerShip.excitement)
  {
    rect(width * 0.01, 0,  width * 0.4 * playerShip.excitement, height * 0.001);
    textAlign(RIGHT, BOTTOM);
    if(playerShip.cloakActivation == 0)
    {
      String labelWeapons = "regional  supremacy  assertion  ONLINE";
      text(labelWeapons, width * 0.41, height * -0.01);
    }
  }
  textAlign(LEFT, TOP);
  String labelExcite = "HELM  GUIDANCE        " + int(playerShip.excitement * 100) + " %";
  text(labelExcite, width * 0.01, height * 0.01);
  if(0 < playerShip.cloakActivation)
  {
    rect(width * -0.01, 0,  -width * 0.4 * playerShip.cloakActivation, height * 0.001);
    if(playerShip.cloaked)
    {
      textAlign(LEFT, BOTTOM);
      String labelDeactive = "power  conservation  mode  ACTIVE";
      text(labelDeactive, width * -0.41, height * -0.01);
    }
  }
  textAlign(RIGHT, TOP);
  String labelCloak = int(playerShip.cloakActivation * 100) + " %         STEALTH  CAPACITORS";
  text(labelCloak, width * -0.01, height * 0.01);
  
  // Draw targeting array down the left
  pushMatrix();
  translate(width * -0.41, height * -0.04);
  scale(0.5);
  textAlign(LEFT, BOTTOM);
  String targetingList = "";//"regional  space  survey \n    scan items";
  Iterator iShips = sceneShipManager.ships.iterator();
  iShips.next();
  while( iShips.hasNext() )
  {
    Ship s = (Ship) iShips.next();
    PVector pos = s.getRoot().getWorldPosition();
    String label = "\n" + s;
    label += "\n    " + pos.x;
    label += ",  " + pos.y;
    targetingList += label;
  }
  targetingList += "\n\nPRAScan\nregional  space  survey \n    scan items";
  text(targetingList, 0,0);
  popMatrix();
  
  
  // Draw movement block at right
  pushMatrix();
  translate(width * 0.41, height * -0.04);
  textAlign(RIGHT, BOTTOM);
  String textRight = "";
  // Draw fps
  textRight += int(frameRate) + "  fps\n";
  // Draw story time
  textRight += int(story.tickTotal) + "  clock cycles\n";
  textRight += int( millis() ) + "  ms  uptime\n";
  // Draw movement
  PVector playerPos = playerShip.getRoot().getWorldPosition();
  // Measuring in femtoparsecs, the screen is ~ 3km tall
  textRight += (int)playerPos.x + "  fpc\n" + (int)playerPos.y + "  fpc\n";
  textRight += (int)degrees( playerShip.getRoot().getWorldRotation() ) + "\n";
  
  text(textRight, 0,0);
  
  popMatrix();
  
  
  popStyle();
  popMatrix();
}
// drawHUD




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
