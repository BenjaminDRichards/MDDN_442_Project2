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
int MIN_SHIP_COUNT = 8;

PGraphics output;              // Used for accelerated draw on slower machines
PVector bufferRes;
RenderManager renderManager, renderManagerScreen;

Capture cam;
boolean camConnected;
BackgroundLearner bgLearn;
MotionCursor motionCursor;
boolean diagnoseBuffers;
color GUI_COLOR = color(255, 192, 64);

ArrayList sceneLights;

PImage lightStencil;
PGraphics testShipSprite;
PGraphics tex_flatWhite, tex_flatBlack, tex_flatNorm, tex_flatNull;
PImage tex_backdrop, tex_warpBackdrop;

PImage fx_shockwave, fx_ray1, fx_ray2, fx_ray1pc, fx_ray2pc;
PImage fx_puff1, fx_puff2, fx_puff3, fx_puff1pc, fx_puff2pc, fx_puff3pc;
PImage fx_spatter, fx_spatterPc, fx_spatterBlack;
PImage fx_streak, fx_streakPC;
PImage fx_wrinkle8, fx_wrinkle64, fx_wrinkle256;

PImage hud_reticule;

PImage ship_preya_bridge_diff;
PImage ship_preya_bridge_norm;
PImage ship_preya_drive_diff;
PImage ship_preya_drive_norm;
PImage ship_preya_inner_diff;
PImage ship_preya_inner_norm;
PImage ship_preya_motor1L_diff;
PImage ship_preya_motor1L_norm;
PImage ship_preya_motor1R_diff;
PImage ship_preya_motor1R_norm;
PImage ship_preya_motor2L_diff;
PImage ship_preya_motor2L_norm;
PImage ship_preya_motor2R_diff;
PImage ship_preya_motor2R_norm;
PImage ship_preya_motor3L_diff;
PImage ship_preya_motor3L_norm;
PImage ship_preya_motor3R_diff;
PImage ship_preya_motor3R_norm;
PImage ship_preya_prow_diff;
PImage ship_preya_prow_norm;
PImage ship_preya_thrusterArmL_diff;
PImage ship_preya_thrusterArmL_norm;
PImage ship_preya_thrusterArmR_diff;
PImage ship_preya_thrusterArmR_norm;
PImage ship_preya_thrusterL_diff;
PImage ship_preya_thrusterL_norm;
PImage ship_preya_thrusterR_diff;
PImage ship_preya_thrusterR_norm;

PImage ship_preya_bridge_warp;
PImage ship_preya_drive_warp;
PImage ship_preya_inner_warp;
PImage ship_preya_motor1L_warp;
PImage ship_preya_motor1R_warp;
PImage ship_preya_motor2L_warp;
PImage ship_preya_motor2R_warp;
PImage ship_preya_motor3L_warp;
PImage ship_preya_motor3R_warp;
PImage ship_preya_prow_warp;
PImage ship_preya_thrusterArmL_warp;
PImage ship_preya_thrusterArmR_warp;
PImage ship_preya_thrusterL_warp;
PImage ship_preya_thrusterR_warp;


void setup()
{
  size(displayWidth, displayHeight, P2D);
  //size(1280, 720, P2D);
  
  noCursor();
  
  
  // Generate resources
  tex_flatWhite = createGraphics(1,1,P2D);
  tex_flatWhite.beginDraw();
  tex_flatWhite.background(255);
  tex_flatWhite.endDraw();
  
  tex_flatBlack = createGraphics(1,1,P2D);
  tex_flatBlack.beginDraw();
  tex_flatBlack.background(0);
  tex_flatBlack.endDraw();
  
  tex_flatNorm = createGraphics(1,1,P2D);
  tex_flatNorm.beginDraw();
  tex_flatNorm.background(127,127,255);
  tex_flatNorm.endDraw();
  
  tex_flatNull = createGraphics(1,1,P2D);
  tex_flatNull.beginDraw();
  tex_flatNull.clear();
  tex_flatNull.endDraw();
  
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
  
  
  // Load resources
  lightStencil = loadImage("images/lightStencil16.png");
  
  tex_backdrop = loadImage("images/starscape2-suns.png");
  tex_warpBackdrop = loadImage("images/windowGlass5.png");
  
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
  fx_wrinkle8 = loadImage("images/effects/wrinkle8.png");
  fx_wrinkle64 = loadImage("images/effects/wrinkle64.png");
  fx_wrinkle256 = loadImage("images/effects/wrinkle256.png");
  
  hud_reticule = loadImage("images/hud/HUDreticule.png");
  
  ship_preya_bridge_diff = loadImage("images/ships/PreyA/PreyA_bridge_diff.png");
  ship_preya_bridge_norm = loadImage("images/ships/PreyA/PreyA_bridge_norm.png");
  ship_preya_drive_diff = loadImage("images/ships/PreyA/PreyA_drive_diff.png");
  ship_preya_drive_norm = loadImage("images/ships/PreyA/PreyA_drive_norm.png");
  ship_preya_inner_diff = loadImage("images/ships/PreyA/PreyA_inner_diff.png");
  ship_preya_inner_norm = loadImage("images/ships/PreyA/PreyA_inner_norm.png");
  ship_preya_motor1L_diff = loadImage("images/ships/PreyA/PreyA_motor1L_diff.png");
  ship_preya_motor1L_norm = loadImage("images/ships/PreyA/PreyA_motor1L_norm.png");
  ship_preya_motor1R_diff = loadImage("images/ships/PreyA/PreyA_motor1R_diff.png");
  ship_preya_motor1R_norm = loadImage("images/ships/PreyA/PreyA_motor1R_norm.png");
  ship_preya_motor2L_diff = loadImage("images/ships/PreyA/PreyA_motor2L_diff.png");
  ship_preya_motor2L_norm = loadImage("images/ships/PreyA/PreyA_motor2L_norm.png");
  ship_preya_motor2R_diff = loadImage("images/ships/PreyA/PreyA_motor2R_diff.png");
  ship_preya_motor2R_norm = loadImage("images/ships/PreyA/PreyA_motor2R_norm.png");
  ship_preya_motor3L_diff = loadImage("images/ships/PreyA/PreyA_motor3L_diff.png");
  ship_preya_motor3L_norm = loadImage("images/ships/PreyA/PreyA_motor3L_norm.png");
  ship_preya_motor3R_diff = loadImage("images/ships/PreyA/PreyA_motor3R_diff.png");
  ship_preya_motor3R_norm = loadImage("images/ships/PreyA/PreyA_motor3R_norm.png");
  ship_preya_prow_diff = loadImage("images/ships/PreyA/PreyA_prow_diff.png");
  ship_preya_prow_norm = loadImage("images/ships/PreyA/PreyA_prow_norm.png");
  ship_preya_thrusterArmL_diff = loadImage("images/ships/PreyA/PreyA_thrusterArmL_diff.png");
  ship_preya_thrusterArmL_norm = loadImage("images/ships/PreyA/PreyA_thrusterArmL_norm.png");
  ship_preya_thrusterArmR_diff = loadImage("images/ships/PreyA/PreyA_thrusterArmR_diff.png");
  ship_preya_thrusterArmR_norm = loadImage("images/ships/PreyA/PreyA_thrusterArmR_norm.png");
  ship_preya_thrusterL_diff = loadImage("images/ships/PreyA/PreyA_thrusterL_diff.png");
  ship_preya_thrusterL_norm = loadImage("images/ships/PreyA/PreyA_thrusterL_norm.png");
  ship_preya_thrusterR_diff = loadImage("images/ships/PreyA/PreyA_thrusterR_diff.png");
  ship_preya_thrusterR_norm = loadImage("images/ships/PreyA/PreyA_thrusterR_norm.png");
  
  // Load generated smooth warp fields
  ship_preya_bridge_warp = loadImage("images/ships/PreyA/PreyA_bridge_warp.png");
  ship_preya_drive_warp = loadImage("images/ships/PreyA/PreyA_drive_warp.png");
  ship_preya_inner_warp = loadImage("images/ships/PreyA/PreyA_inner_warp.png");
  ship_preya_motor1L_warp = loadImage("images/ships/PreyA/PreyA_motor1L_warp.png");
  ship_preya_motor1R_warp = loadImage("images/ships/PreyA/PreyA_motor1R_warp.png");
  ship_preya_motor2L_warp = loadImage("images/ships/PreyA/PreyA_motor2L_warp.png");
  ship_preya_motor2R_warp = loadImage("images/ships/PreyA/PreyA_motor2R_warp.png");
  ship_preya_motor3L_warp = loadImage("images/ships/PreyA/PreyA_motor3L_warp.png");
  ship_preya_motor3R_warp = loadImage("images/ships/PreyA/PreyA_motor3R_warp.png");
  ship_preya_prow_warp = loadImage("images/ships/PreyA/PreyA_prow_warp.png");
  ship_preya_thrusterArmL_warp = loadImage("images/ships/PreyA/PreyA_thrusterArmL_warp.png");
  ship_preya_thrusterArmR_warp = loadImage("images/ships/PreyA/PreyA_thrusterArmR_warp.png");
  ship_preya_thrusterL_warp = loadImage("images/ships/PreyA/PreyA_thrusterL_warp.png");
  ship_preya_thrusterR_warp = loadImage("images/ships/PreyA/PreyA_thrusterR_warp.png");
  
  
  // Setup story
  story = new Story();
  
  
  // Setup draw buffer
  // Comply with screen aspect ratio
  float outputResX = 1920;
  float outputResY = 1080;
  float expectedRatio = outputResX / outputResY;
  float actualRatio = width / (float)height;
  if(actualRatio < expectedRatio)    outputResX = outputResY * actualRatio;
  else                               outputResY = outputResX / actualRatio;
  if(width < outputResX)
  {
    // Downsize buffer
    outputResX = width;
    outputResY = height;
  }
  bufferRes = new PVector(outputResX, outputResY);
  output = createGraphics( int(bufferRes.x), int(bufferRes.y), P2D);
  
  
  // Setup renderers
  renderManager = new RenderManager(output);
  renderManager.fullWarp = tex_flatNorm;
  renderManager.doBloom = true;
  
  renderManagerScreen = new RenderManager(g);
  renderManagerScreen.bBackground = output;
  renderManagerScreen.fullWarp = tex_warpBackdrop;
  
  
  
  // Setup constant lights
  sceneLights = new ArrayList();
  // Directional lights
  DAGTransform dirlDag = new DAGTransform(0,0,0, 0, 1,1,1);  // Necessary evil
  Light dirl = new Light(dirlDag, 0.2, color(192, 222, 255, 255));
  dirl.makeDirectional( new PVector(0.2, -1, 0.2) );
  sceneLights.add(dirl);
  dirl = new Light(dirlDag, 0.2, color(255,247,255, 255));
  dirl.makeDirectional( new PVector(-1, -1, 0.3) );
  sceneLights.add(dirl);
  /*
  RGB test lights
  dirlDag = new DAGTransform(0,0,0, 0, 1,1,1);  // Necessary evil
  dirl = new Light(dirlDag, 0.6, color(255, 0, 0, 255));
  dirl.makeDirectional( new PVector(-0.0, -1, -0.0) );
  sceneLights.add(dirl);
  dirl = new Light(dirlDag, 0.6, color(0, 255, 0, 255));
  dirl.makeDirectional( new PVector(1, 0, -0.0) );
  sceneLights.add(dirl);
  dirl = new Light(dirlDag, 0.6, color(0, 0, 255, 255));
  dirl.makeDirectional( new PVector(0, 0, 1.0) );
  sceneLights.add(dirl);
  */
  
  
  
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
  for(int i = 0;  i < MIN_SHIP_COUNT;  i++)
  {
    spawnShipPreyA();
  }
  
  
  
  // Setup camera
  String[] cameras = Capture.list();
  if (cameras.length == 0)
  {
    println("There are no cameras available for capture.");
    //exit();
    // Reconfigure for mouse input
    //playerShip.navMode = Ship.NAV_MODE_MOUSE;
    camConnected = false;
  }
  else
  {
    // Initialise camera from list
    // My list has a 640*480 30fps feed at position 1
    //cam = new Capture(this, cameras[1]);
    // But for generic lists I'll be more specific:
    cam = new Capture(this, 320, 240, 30); 
    cam.start();
    camConnected = true;
    // Make certain the camera has begun
    // This is necessary for the BackgroundLearner to work
    while( !cam.available() )
    {
      killTime(1.0);
    }
    
    // Setup camera systems
    bgLearn = new BackgroundLearner(cam);
  }
  motionCursor = new MotionCursor();
  motionCursor.setDrawTarget(output);
  motionCursor.run(tex_flatWhite);      // Pretouch systems
  diagnoseBuffers = false;
}
// setup





void draw()
{
  /*
  CONTROL
  */
  
  // Handle camera input
  if(camConnected)
  {
    cam.read();
    bgLearn.run();
    motionCursor.run( bgLearn.getHeatIso() );
    motionCursor.pipHeight = bgLearn.pipHeight;
  }
  else
  {
    motionCursor.setCursorNormalized(mouseX / (float)width, mouseY / (float)height);
  }
  // Control player ship
  PVector playerTarget = motionCursor.getCursorNormalized();
  playerShip.setExternalVector( new PVector(toPercent( (playerTarget.x - 0.5) * output.width ),
                                            toPercent(playerTarget.y * output.height),
                                            0.0) );
  
  
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
  
  // Perform final render
  renderManager.render();
  
  
  
  /*
  UI DRAW
  */
  
  // Draw excitement meters and HUD
  output.beginDraw();
  drawHUD(output);
  output.endDraw();
  
  
  /*
  FINAL VISUAL COMPOSIT
  */
  /*
  // Unfiltered output
  image(output, 0,0, width, height);
  */
  // Post-processed output
  renderManagerScreen.render();
  
  
  
  /*
  Diagnostics
  */
  
  // Visualise camera systems
  if(diagnoseBuffers)
  {
    bgLearn.diagnoseBuffers();
    motionCursor.diagnose();
  }
  
  //image(ship_preya_bridge_warp, 0,0);
  
  //background(255);
  //image(renderManager.bNormal, 0,0, width, height);
  //image(renderManager.bWarp, 0,0, width, height);
  
  if(frameCount % 60 == 0)
  {
    //println("FPS " + frameRate);
    
    //println("Cloak: " + playerShip.cloaked + ", cloakActivation " + playerShip.cloakActivation
    //    + ", excitement " + playerShip.excitement);
  }
}
// draw


void keyPressed()
{
  if( key == 'S'  ||  key == 's' )  {  spawnShipPreyA();  }
  
  if( (key == '~'  ||  key == '`')  &&  camConnected )  {  diagnoseBuffers = !diagnoseBuffers;  }
  
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
{  return( toPercent(x - width * 0.5) );  }
float toPercentY(float y)
{  return( toPercent(y) );  }
float toPercent(float n)
{  return( n * 100.0 / height );  }

float fromPercentX(float x)
{  return( fromPercent(x) + bufferRes.x * 0.5 );  }
float fromPercentY(float y)
{  return( fromPercent(y) );  }
float fromPercent(float n)
{  return( n * bufferRes.y * 0.01 );  }


void spawnShipPreyA()
{
  PVector pos = new PVector(random(-60,60), -10, 0);
  PVector targetPos = pos.get();
  targetPos.add( PVector.random3D() );
  sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_PREY_A, 0);
}


void drawHUD(PGraphics pg)
{
  // Draw motion cursor tracking data
  motionCursor.renderMoVis();
  
  float cloakDim = 1.0 - 0.5 * playerShip.cloakActivation;
  
  // Draw activity meters
  pg.pushMatrix();
  pg.pushStyle();
  
  pg.noStroke();
  pg.fill(GUI_COLOR, 127 * cloakDim);
  pg.textSize(18 * pg.height / 1080.0);
  pg.translate(pg.width * 0.5, pg.height * 0.9);
  if(0 < playerShip.excitement)
  {
    pg.rect(pg.width * 0.01, 0,  pg.width * 0.4 * playerShip.excitement, pg.height * 0.001);
    pg.textAlign(RIGHT, BOTTOM);
    if(playerShip.cloakActivation == 0)
    {
      String labelWeapons = "regional  supremacy  assertion  ONLINE";
      pg.text(labelWeapons, pg.width * 0.41, pg.height * -0.01);
    }
  }
  pg.textAlign(LEFT, TOP);
  String labelExcite = "HELM  GUIDANCE        " + int(playerShip.excitement * 100) + " %";
  pg.text(labelExcite, pg.width * 0.01, pg.height * 0.01);
  if(0 < playerShip.cloakActivation)
  {
    pg.rect(pg.width * -0.01, 0,  -pg.width * 0.4 * playerShip.cloakActivation, pg.height * 0.001);
    if(playerShip.cloaked)
    {
      pg.textAlign(LEFT, BOTTOM);
      String labelDeactive = "power  conservation  mode  ACTIVE";
      pg.text(labelDeactive, pg.width * -0.41, pg.height * -0.01);
    }
  }
  pg.textAlign(RIGHT, TOP);
  String labelCloak = int(playerShip.cloakActivation * 100) + " %         STEALTH  CAPACITORS";
  pg.text(labelCloak, pg.width * -0.01, pg.height * 0.01);
  
  /*
  SET DRESSING
  */
  pg.fill(GUI_COLOR, 64 * cloakDim);
  
  // Draw targeting array down the left
  pg.pushMatrix();
  pg.translate(pg.width * -0.41, pg.height * -0.04);
  pg.scale(0.5);
  pg.textAlign(LEFT, BOTTOM);
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
  pg.text(targetingList, 0,0);
  pg.popMatrix();
  
  
  // Draw movement block at right
  pg.pushMatrix();
  pg.translate(pg.width * 0.41, pg.height * -0.04);
  pg.textAlign(RIGHT, BOTTOM);
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
  // Draw artist name
  textRight += "MANTLE.mddn442.benjamin.d.richards.20130628\n";
  
  pg.text(textRight, 0,0);
  
  pg.popMatrix();
  
  
  pg.popStyle();
  pg.popMatrix();
}
// drawHUD



PGraphics normalToWarp(PImage normalSource, String name)
// Fuzz out the edges of a normal map to create nice warp falloff
// This was used to generate all the warp textures
{
  PGraphics warpBlur = createGraphics(normalSource.width, normalSource.height, P2D);
  warpBlur.beginDraw();
  warpBlur.clear();
  // Fill with invisible flat-normals
  warpBlur.loadPixels();
  for(int i = 0;  i < warpBlur.pixels.length;  i++)
  {
    warpBlur.pixels[i] = color(127,127,255,0);
  }
  warpBlur.updatePixels();
  warpBlur.image(normalSource,  0, 0,  warpBlur.width, warpBlur.height);
  warpBlur.filter(BLUR, normalSource.width / 32.0);
  warpBlur.endDraw();
  
  PGraphics warpBlurBig = createGraphics(normalSource.width, normalSource.height, P2D);
  warpBlurBig.beginDraw();
  warpBlurBig.clear();
  // Fill with invisible flat-normals
  warpBlurBig.loadPixels();
  for(int i = 0;  i < warpBlurBig.pixels.length;  i++)
  {
    warpBlurBig.pixels[i] = color(127,127,255,0);
  }
  warpBlurBig.updatePixels();
  warpBlurBig.image(normalSource,  0, 0,  warpBlurBig.width, warpBlurBig.height);
  warpBlurBig.filter(BLUR, normalSource.width / 16.0);
  warpBlurBig.endDraw();
  
  PGraphics warp = createGraphics(normalSource.width, normalSource.height, P2D);
  warp.beginDraw();
  warp.clear();
  warp.image(normalSource,  0, 0,  warp.width, warp.height);
  warp.loadPixels();
  warpBlur.loadPixels();
  for(int i = 0;  i < warp.pixels.length;  i++)
  {
    color wCol = warp.pixels[i];
    color waCol = warpBlur.pixels[i];
    wCol = lerpColor(wCol, waCol, 1.0 - alpha(waCol) / 255.0);
    wCol = color( red(wCol), green(wCol), blue(wCol), 2.0 * alpha(wCol) - 255 );
    warp.pixels[i] = wCol;
  }
  warp.updatePixels();
  warp.endDraw();
  
  // Final composite
  warpBlurBig.beginDraw();
  warpBlurBig.image(warpBlur,  0, 0,  warpBlurBig.width, warpBlurBig.height);
  warpBlurBig.image(warp,  0, 0,  warpBlurBig.width, warpBlurBig.height);
  warpBlurBig.endDraw();
  
  println("Warped " + name);
  warpBlurBig.save("data/images/ships/PreyA/" + name + ".png");
  
  return( warpBlurBig );
}
// normalToWarp




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
