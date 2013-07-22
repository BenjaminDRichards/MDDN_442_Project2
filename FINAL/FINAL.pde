/*
  Ship navigation and animation program
  
  This code generates and controls some ships that fly around.
  They use DAG nodes for sub-animation and positioning.
*/


import java.util.*;
import processing.video.*;


Story story;
boolean paused;

ShipManager sceneShipManager, dressageShipManager;
Ship playerShip;
int MIN_SHIP_COUNT = 8;

PGraphics output;              // Where the main drawing gets done
PVector bufferRes;
PVector overrideRes;
RenderManager renderManager;
Hud hud;

Capture cam;
boolean camConnected, camActive;
BackgroundLearner bgLearn;
MotionCursor motionCursor;
boolean diagnoseBuffers;
color GUI_COLOR = color(255, 192, 96);

ArrayList sceneLights;

PFont font;
PImage lightStencil;
PGraphics testShipSprite;
PGraphics tex_flatWhite, tex_flatBlack, tex_flatNorm, tex_flatNull;
PImage tex_backdrop, tex_warpBackdrop;

PImage fx_shockwave, fx_spatter, fx_streak;
PImage fx_ray1, fx_ray2;
PImage fx_puff1, fx_puff2, fx_puff3;
PImage fx_puff1norm, fx_puff2norm, fx_puff3norm;
PImage fx_jet;
PImage fx_wrinkle8, fx_wrinkle64, fx_wrinkle256;

PImage hud_reticule;
PImage hud_element_helm, hud_element_offline, hud_element_online, hud_element_stealth;

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
PImage ship_preya_turret_diff;
PImage ship_preya_turret_norm;

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
PImage ship_preya_turret_warp;

PImage ship_mantle_keel_diff, ship_mantle_keel_norm, ship_mantle_keel_warp;
PImage ship_mantle_tail1_diff, ship_mantle_tail1_norm, ship_mantle_tail1_warp;
PImage ship_mantle_tail2_diff, ship_mantle_tail2_norm, ship_mantle_tail2_warp;
PImage ship_mantle_tail3_diff, ship_mantle_tail3_norm, ship_mantle_tail3_warp;
PImage ship_mantle_tailL1_diff, ship_mantle_tailL1_norm, ship_mantle_tailL1_warp;
PImage ship_mantle_tailL2_diff, ship_mantle_tailL2_norm, ship_mantle_tailL2_warp;
PImage ship_mantle_tailL3_diff, ship_mantle_tailL3_norm, ship_mantle_tailL3_warp;
PImage ship_mantle_tailR1_diff, ship_mantle_tailR1_norm, ship_mantle_tailR1_warp;
PImage ship_mantle_tailR2_diff, ship_mantle_tailR2_norm, ship_mantle_tailR2_warp;
PImage ship_mantle_tailR3_diff, ship_mantle_tailR3_norm, ship_mantle_tailR3_warp;
PImage ship_mantle_tailTip_diff, ship_mantle_tailTip_norm, ship_mantle_tailTip_warp;
PImage ship_mantle_turret_diff, ship_mantle_turret_norm, ship_mantle_turret_warp;
PImage ship_mantle_wing1L_diff, ship_mantle_wing1L_norm, ship_mantle_wing1L_warp;
PImage ship_mantle_wing1R_diff, ship_mantle_wing1R_norm, ship_mantle_wing1R_warp;
PImage ship_mantle_wing2L_diff, ship_mantle_wing2L_norm, ship_mantle_wing2L_warp;
PImage ship_mantle_wing2R_diff, ship_mantle_wing2R_norm, ship_mantle_wing2R_warp;

PImage debris_01_diff, debris_01_norm;
PImage debris_02_diff, debris_02_norm;
PImage debris_03_diff, debris_03_norm;
PImage debris_04_diff, debris_04_norm;
PImage debris_05_diff, debris_05_norm;
PImage debris_06_diff, debris_06_norm;
PImage debris_07_diff, debris_07_norm;
PImage debris_08_diff, debris_08_norm;
PImage debris_09_diff, debris_09_norm;
PImage debris_10_diff, debris_10_norm;
PImage debris_11_diff, debris_11_norm;
PImage debris_12_diff, debris_12_norm;
PImage debris_13_diff, debris_13_norm;
PImage debris_14_diff, debris_14_norm;
PImage debris_15_diff, debris_15_norm;
PImage debris_16_diff, debris_16_norm;
PImage debris_17_diff, debris_17_norm;
PImage debris_18_diff, debris_18_norm;
PImage debris_19_diff, debris_19_norm;
PImage debris_20_diff, debris_20_norm;
PImage debris_21_diff, debris_21_norm;
PImage debris_22_diff, debris_22_norm;
PImage debris_23_diff, debris_23_norm;
PImage debris_24_diff, debris_24_norm;

PImage debris_dust;


void setup()
{
  // Letterbox parameters
  float resX = displayWidth;
  float resY = displayHeight;
  float idealRatio = 16.0 / 9.0;
  float screenRatio = displayWidth / (float)displayHeight;
  if(screenRatio < idealRatio)
  {
    // That is, the screen is too tall
    // Downres in Y
    resY = displayWidth / idealRatio;
  }
  else if(idealRatio < screenRatio)
  {
    // That is, the screen is too wide
    // Downres in X
    resX = displayHeight * idealRatio;
  }
  
  /*
  SET RESOLUTION
  */
  size(int(resX), int(resY), P2D);
  //size(640, 360, P2D);            // For diagnostics - currently, it doesn't run much faster
  //size(2480, 1395, P2D);          // For renders - this fits horizontally on portrait A4 
                                    //  - crazy high, doesn't run at all cooperatively
  //frameRate(30);                    // Because it's plenty smooth at 30 and 15 is too low
  
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
  float scaleFactor = 0.25 * height / 1080;
  
  lightStencil = loadImage("images/lightStencil16.png");
  
  tex_backdrop = loadImageScaled("images/starscape4.png", scaleFactor * 2.0 );
  tex_warpBackdrop = loadImage("images/windowGlass5.png");
  
  fx_shockwave = loadImageScaled("images/effects/shockwave2.png", scaleFactor);
  fx_spatter = loadImage("images/effects/spatter2.png");
  fx_streak = loadImage("images/effects/streak.png");
  fx_ray1 = loadImage("images/effects/ray1.png");
  fx_ray2 = loadImage("images/effects/ray2.png");
  fx_puff1 = loadImage("images/effects/puff1.png");
  fx_puff2 = loadImage("images/effects/puff2.png");
  fx_puff3 = loadImage("images/effects/puff3.png");
  fx_puff1norm = loadImage("images/effects/puff1norm.png");
  fx_puff2norm = loadImage("images/effects/puff2norm.png");
  fx_puff3norm = loadImage("images/effects/puff3norm.png");
  fx_jet = loadImage("images/effects/jet.png");
  fx_wrinkle8 = loadImageScaled("images/effects/wrinkle8.png", scaleFactor);
  fx_wrinkle64 = loadImageScaled("images/effects/wrinkle64.png", scaleFactor);
  fx_wrinkle256 = loadImageScaled("images/effects/wrinkle256.png", scaleFactor);
  
  hud_reticule = loadImage("images/hud/HUDreticule.png");
  hud_element_helm = loadImage("images/hud/HUD_elements_helm.png");
  hud_element_offline = loadImage("images/hud/HUD_elements_offline.png");
  hud_element_online = loadImage("images/hud/HUD_elements_online.png");
  hud_element_stealth = loadImage("images/hud/HUD_elements_stealth.png");
  
  ship_preya_bridge_diff = loadImageScaled("images/ships/PreyA/PreyA_bridge_diff.png", scaleFactor);
  ship_preya_bridge_norm = loadImageScaled("images/ships/PreyA/PreyA_bridge_norm.png", scaleFactor);
  ship_preya_drive_diff = loadImageScaled("images/ships/PreyA/PreyA_drive_diff.png", scaleFactor);
  ship_preya_drive_norm = loadImageScaled("images/ships/PreyA/PreyA_drive_norm.png", scaleFactor);
  ship_preya_inner_diff = loadImageScaled("images/ships/PreyA/PreyA_inner_diff.png", scaleFactor);
  ship_preya_inner_norm = loadImageScaled("images/ships/PreyA/PreyA_inner_norm.png", scaleFactor);
  ship_preya_motor1L_diff = loadImageScaled("images/ships/PreyA/PreyA_motor1L_diff.png", scaleFactor);
  ship_preya_motor1L_norm = loadImageScaled("images/ships/PreyA/PreyA_motor1L_norm.png", scaleFactor);
  ship_preya_motor1R_diff = loadImageScaled("images/ships/PreyA/PreyA_motor1R_diff.png", scaleFactor);
  ship_preya_motor1R_norm = loadImageScaled("images/ships/PreyA/PreyA_motor1R_norm.png", scaleFactor);
  ship_preya_motor2L_diff = loadImageScaled("images/ships/PreyA/PreyA_motor2L_diff.png", scaleFactor);
  ship_preya_motor2L_norm = loadImageScaled("images/ships/PreyA/PreyA_motor2L_norm.png", scaleFactor);
  ship_preya_motor2R_diff = loadImageScaled("images/ships/PreyA/PreyA_motor2R_diff.png", scaleFactor);
  ship_preya_motor2R_norm = loadImageScaled("images/ships/PreyA/PreyA_motor2R_norm.png", scaleFactor);
  ship_preya_motor3L_diff = loadImageScaled("images/ships/PreyA/PreyA_motor3L_diff.png", scaleFactor);
  ship_preya_motor3L_norm = loadImageScaled("images/ships/PreyA/PreyA_motor3L_norm.png", scaleFactor);
  ship_preya_motor3R_diff = loadImageScaled("images/ships/PreyA/PreyA_motor3R_diff.png", scaleFactor);
  ship_preya_motor3R_norm = loadImageScaled("images/ships/PreyA/PreyA_motor3R_norm.png", scaleFactor);
  ship_preya_prow_diff = loadImageScaled("images/ships/PreyA/PreyA_prow_diff.png", scaleFactor);
  ship_preya_prow_norm = loadImageScaled("images/ships/PreyA/PreyA_prow_norm.png", scaleFactor);
  ship_preya_thrusterArmL_diff = loadImageScaled("images/ships/PreyA/PreyA_thrusterArmL_diff.png", scaleFactor);
  ship_preya_thrusterArmL_norm = loadImageScaled("images/ships/PreyA/PreyA_thrusterArmL_norm.png", scaleFactor);
  ship_preya_thrusterArmR_diff = loadImageScaled("images/ships/PreyA/PreyA_thrusterArmR_diff.png", scaleFactor);
  ship_preya_thrusterArmR_norm = loadImageScaled("images/ships/PreyA/PreyA_thrusterArmR_norm.png", scaleFactor);
  ship_preya_thrusterL_diff = loadImageScaled("images/ships/PreyA/PreyA_thrusterL_diff.png", scaleFactor);
  ship_preya_thrusterL_norm = loadImageScaled("images/ships/PreyA/PreyA_thrusterL_norm.png", scaleFactor);
  ship_preya_thrusterR_diff = loadImageScaled("images/ships/PreyA/PreyA_thrusterR_diff.png", scaleFactor);
  ship_preya_thrusterR_norm = loadImageScaled("images/ships/PreyA/PreyA_thrusterR_norm.png", scaleFactor);
  ship_preya_turret_diff = loadImageScaled("images/ships/PreyA/PreyA_turret_diff.png", scaleFactor);
  ship_preya_turret_norm = loadImageScaled("images/ships/PreyA/PreyA_turret_norm.png", scaleFactor);
  
  // Load generated smooth warp fields
  ship_preya_bridge_warp = loadImageScaled("images/ships/PreyA/PreyA_bridge_warp.png", scaleFactor);
  ship_preya_drive_warp = loadImageScaled("images/ships/PreyA/PreyA_drive_warp.png", scaleFactor);
  ship_preya_inner_warp = loadImageScaled("images/ships/PreyA/PreyA_inner_warp.png", scaleFactor);
  ship_preya_motor1L_warp = loadImageScaled("images/ships/PreyA/PreyA_motor1L_warp.png", scaleFactor);
  ship_preya_motor1R_warp = loadImageScaled("images/ships/PreyA/PreyA_motor1R_warp.png", scaleFactor);
  ship_preya_motor2L_warp = loadImageScaled("images/ships/PreyA/PreyA_motor2L_warp.png", scaleFactor);
  ship_preya_motor2R_warp = loadImageScaled("images/ships/PreyA/PreyA_motor2R_warp.png", scaleFactor);
  ship_preya_motor3L_warp = loadImageScaled("images/ships/PreyA/PreyA_motor3L_warp.png", scaleFactor);
  ship_preya_motor3R_warp = loadImageScaled("images/ships/PreyA/PreyA_motor3R_warp.png", scaleFactor);
  ship_preya_prow_warp = loadImageScaled("images/ships/PreyA/PreyA_prow_warp.png", scaleFactor);
  ship_preya_thrusterArmL_warp = loadImageScaled("images/ships/PreyA/PreyA_thrusterArmL_warp.png", scaleFactor);
  ship_preya_thrusterArmR_warp = loadImageScaled("images/ships/PreyA/PreyA_thrusterArmR_warp.png", scaleFactor);
  ship_preya_thrusterL_warp = loadImageScaled("images/ships/PreyA/PreyA_thrusterL_warp.png", scaleFactor);
  ship_preya_thrusterR_warp = loadImageScaled("images/ships/PreyA/PreyA_thrusterR_warp.png", scaleFactor);
  ship_preya_turret_warp = loadImageScaled("images/ships/PreyA/PreyA_turret_warp.png", scaleFactor);
  
  // LoadMantle ship sprites
  ship_mantle_keel_diff = loadImageScaled("images/ships/Mantle/Mantle_keel_diff.png", scaleFactor);
  ship_mantle_keel_norm = loadImageScaled("images/ships/Mantle/Mantle_keel_norm.png", scaleFactor);
  ship_mantle_keel_warp = loadImageScaled("images/ships/Mantle/Mantle_keel_warp.png", scaleFactor);
  ship_mantle_tail1_diff = loadImageScaled("images/ships/Mantle/Mantle_tail1_diff.png", scaleFactor);
  ship_mantle_tail1_norm = loadImageScaled("images/ships/Mantle/Mantle_tail1_norm.png", scaleFactor);
  ship_mantle_tail1_warp = loadImageScaled("images/ships/Mantle/Mantle_tail1_warp.png", scaleFactor);
  ship_mantle_tail2_diff = loadImageScaled("images/ships/Mantle/Mantle_tail2_diff.png", scaleFactor);
  ship_mantle_tail2_norm = loadImageScaled("images/ships/Mantle/Mantle_tail2_norm.png", scaleFactor);
  ship_mantle_tail2_warp = loadImageScaled("images/ships/Mantle/Mantle_tail2_warp.png", scaleFactor);
  ship_mantle_tail3_diff = loadImageScaled("images/ships/Mantle/Mantle_tail3_diff.png", scaleFactor);
  ship_mantle_tail3_norm = loadImageScaled("images/ships/Mantle/Mantle_tail3_norm.png", scaleFactor);
  ship_mantle_tail3_warp = loadImageScaled("images/ships/Mantle/Mantle_tail3_warp.png", scaleFactor);
  ship_mantle_tailL1_diff = loadImageScaled("images/ships/Mantle/Mantle_tailL1_diff.png", scaleFactor);
  ship_mantle_tailL1_norm = loadImageScaled("images/ships/Mantle/Mantle_tailL1_norm.png", scaleFactor);
  ship_mantle_tailL1_warp = loadImageScaled("images/ships/Mantle/Mantle_tailL1_warp.png", scaleFactor);
  ship_mantle_tailL2_diff = loadImageScaled("images/ships/Mantle/Mantle_tailL2_diff.png", scaleFactor);
  ship_mantle_tailL2_norm = loadImageScaled("images/ships/Mantle/Mantle_tailL2_norm.png", scaleFactor);
  ship_mantle_tailL2_warp = loadImageScaled("images/ships/Mantle/Mantle_tailL2_warp.png", scaleFactor);
  ship_mantle_tailL3_diff = loadImageScaled("images/ships/Mantle/Mantle_tailL3_diff.png", scaleFactor);
  ship_mantle_tailL3_norm = loadImageScaled("images/ships/Mantle/Mantle_tailL3_norm.png", scaleFactor);
  ship_mantle_tailL3_warp = loadImageScaled("images/ships/Mantle/Mantle_tailL3_warp.png", scaleFactor);
  ship_mantle_tailR1_diff = loadImageScaled("images/ships/Mantle/Mantle_tailR1_diff.png", scaleFactor);
  ship_mantle_tailR1_norm = loadImageScaled("images/ships/Mantle/Mantle_tailR1_norm.png", scaleFactor);
  ship_mantle_tailR1_warp = loadImageScaled("images/ships/Mantle/Mantle_tailR1_warp.png", scaleFactor);
  ship_mantle_tailR2_diff = loadImageScaled("images/ships/Mantle/Mantle_tailR2_diff.png", scaleFactor);
  ship_mantle_tailR2_norm = loadImageScaled("images/ships/Mantle/Mantle_tailR2_norm.png", scaleFactor);
  ship_mantle_tailR2_warp = loadImageScaled("images/ships/Mantle/Mantle_tailR2_warp.png", scaleFactor);
  ship_mantle_tailR3_diff = loadImageScaled("images/ships/Mantle/Mantle_tailR3_diff.png", scaleFactor);
  ship_mantle_tailR3_norm = loadImageScaled("images/ships/Mantle/Mantle_tailR3_norm.png", scaleFactor);
  ship_mantle_tailR3_warp = loadImageScaled("images/ships/Mantle/Mantle_tailR3_warp.png", scaleFactor);
  ship_mantle_tailTip_diff = loadImageScaled("images/ships/Mantle/Mantle_tailTip_diff.png", scaleFactor);
  ship_mantle_tailTip_norm = loadImageScaled("images/ships/Mantle/Mantle_tailTip_norm.png", scaleFactor);
  ship_mantle_tailTip_warp = loadImageScaled("images/ships/Mantle/Mantle_tailTip_warp.png", scaleFactor);
  ship_mantle_turret_diff = loadImageScaled("images/ships/Mantle/Mantle_turret_diff.png", scaleFactor);
  ship_mantle_turret_norm = loadImageScaled("images/ships/Mantle/Mantle_turret_norm.png", scaleFactor);
  ship_mantle_turret_warp = loadImageScaled("images/ships/Mantle/Mantle_turret_warp.png", scaleFactor);
  ship_mantle_wing1L_diff = loadImageScaled("images/ships/Mantle/Mantle_wing1L_diff.png", scaleFactor);
  ship_mantle_wing1L_norm = loadImageScaled("images/ships/Mantle/Mantle_wing1L_norm.png", scaleFactor);
  ship_mantle_wing1L_warp = loadImageScaled("images/ships/Mantle/Mantle_wing1L_warp.png", scaleFactor);
  ship_mantle_wing1R_diff = loadImageScaled("images/ships/Mantle/Mantle_wing1R_diff.png", scaleFactor);
  ship_mantle_wing1R_norm = loadImageScaled("images/ships/Mantle/Mantle_wing1R_norm.png", scaleFactor);
  ship_mantle_wing1R_warp = loadImageScaled("images/ships/Mantle/Mantle_wing1R_warp.png", scaleFactor);
  ship_mantle_wing2L_diff = loadImageScaled("images/ships/Mantle/Mantle_wing2L_diff.png", scaleFactor);
  ship_mantle_wing2L_norm = loadImageScaled("images/ships/Mantle/Mantle_wing2L_norm.png", scaleFactor);
  ship_mantle_wing2L_warp = loadImageScaled("images/ships/Mantle/Mantle_wing2L_warp.png", scaleFactor);
  ship_mantle_wing2R_diff = loadImageScaled("images/ships/Mantle/Mantle_wing2R_diff.png", scaleFactor);
  ship_mantle_wing2R_norm = loadImageScaled("images/ships/Mantle/Mantle_wing2R_norm.png", scaleFactor);
  ship_mantle_wing2R_warp = loadImageScaled("images/ships/Mantle/Mantle_wing2R_warp.png", scaleFactor);
  
  // Load debris sprites
  debris_01_diff = loadImageScaled("images/effects/debris/debris01_diff.png", scaleFactor);
  debris_01_norm = loadImageScaled("images/effects/debris/debris01_norm.png", scaleFactor);
  debris_02_diff = loadImageScaled("images/effects/debris/debris02_diff.png", scaleFactor);
  debris_02_norm = loadImageScaled("images/effects/debris/debris02_norm.png", scaleFactor);
  debris_03_diff = loadImageScaled("images/effects/debris/debris03_diff.png", scaleFactor);
  debris_03_norm = loadImageScaled("images/effects/debris/debris03_norm.png", scaleFactor);
  debris_04_diff = loadImageScaled("images/effects/debris/debris04_diff.png", scaleFactor);
  debris_04_norm = loadImageScaled("images/effects/debris/debris04_norm.png", scaleFactor);
  debris_05_diff = loadImageScaled("images/effects/debris/debris05_diff.png", scaleFactor);
  debris_05_norm = loadImageScaled("images/effects/debris/debris05_norm.png", scaleFactor);
  debris_06_diff = loadImageScaled("images/effects/debris/debris06_diff.png", scaleFactor);
  debris_06_norm = loadImageScaled("images/effects/debris/debris06_norm.png", scaleFactor);
  debris_07_diff = loadImageScaled("images/effects/debris/debris07_diff.png", scaleFactor);
  debris_07_norm = loadImageScaled("images/effects/debris/debris07_norm.png", scaleFactor);
  debris_08_diff = loadImageScaled("images/effects/debris/debris08_diff.png", scaleFactor);
  debris_08_norm = loadImageScaled("images/effects/debris/debris08_norm.png", scaleFactor);
  debris_09_diff = loadImageScaled("images/effects/debris/debris09_diff.png", scaleFactor);
  debris_09_norm = loadImageScaled("images/effects/debris/debris09_norm.png", scaleFactor);
  
  debris_10_diff = loadImageScaled("images/effects/debris/debris10_diff.png", scaleFactor);
  debris_10_norm = loadImageScaled("images/effects/debris/debris10_norm.png", scaleFactor);
  debris_11_diff = loadImageScaled("images/effects/debris/debris11_diff.png", scaleFactor);
  debris_11_norm = loadImageScaled("images/effects/debris/debris11_norm.png", scaleFactor);
  debris_12_diff = loadImageScaled("images/effects/debris/debris12_diff.png", scaleFactor);
  debris_12_norm = loadImageScaled("images/effects/debris/debris12_norm.png", scaleFactor);
  debris_13_diff = loadImageScaled("images/effects/debris/debris13_diff.png", scaleFactor);
  debris_13_norm = loadImageScaled("images/effects/debris/debris13_norm.png", scaleFactor);
  debris_14_diff = loadImageScaled("images/effects/debris/debris14_diff.png", scaleFactor);
  debris_14_norm = loadImageScaled("images/effects/debris/debris14_norm.png", scaleFactor);
  debris_15_diff = loadImageScaled("images/effects/debris/debris15_diff.png", scaleFactor);
  debris_15_norm = loadImageScaled("images/effects/debris/debris15_norm.png", scaleFactor);
  debris_16_diff = loadImageScaled("images/effects/debris/debris16_diff.png", scaleFactor);
  debris_16_norm = loadImageScaled("images/effects/debris/debris16_norm.png", scaleFactor);
  debris_17_diff = loadImageScaled("images/effects/debris/debris17_diff.png", scaleFactor);
  debris_17_norm = loadImageScaled("images/effects/debris/debris17_norm.png", scaleFactor);
  debris_18_diff = loadImageScaled("images/effects/debris/debris18_diff.png", scaleFactor);
  debris_18_norm = loadImageScaled("images/effects/debris/debris18_norm.png", scaleFactor);
  debris_19_diff = loadImageScaled("images/effects/debris/debris19_diff.png", scaleFactor);
  debris_19_norm = loadImageScaled("images/effects/debris/debris19_norm.png", scaleFactor);
  
  debris_20_diff = loadImageScaled("images/effects/debris/debris20_diff.png", scaleFactor);
  debris_20_norm = loadImageScaled("images/effects/debris/debris20_norm.png", scaleFactor);
  debris_21_diff = loadImageScaled("images/effects/debris/debris21_diff.png", scaleFactor);
  debris_21_norm = loadImageScaled("images/effects/debris/debris21_norm.png", scaleFactor);
  debris_22_diff = loadImageScaled("images/effects/debris/debris22_diff.png", scaleFactor);
  debris_22_norm = loadImageScaled("images/effects/debris/debris22_norm.png", scaleFactor);
  debris_23_diff = loadImageScaled("images/effects/debris/debris23_diff.png", scaleFactor);
  debris_23_norm = loadImageScaled("images/effects/debris/debris23_norm.png", scaleFactor);
  debris_24_diff = loadImageScaled("images/effects/debris/debris24_diff.png", scaleFactor);
  debris_24_norm = loadImageScaled("images/effects/debris/debris24_norm.png", scaleFactor);
  
  debris_dust = loadImageScaled("images/effects/debris/SpaceDust.png", scaleFactor * 2.0);
  
  
  // Setup story
  story = new Story();
  
  // Setup pause management
  paused = false;
  
  
  // Setup draw buffer
  float bx = 1.0;
  float by = 1.0;
  if(overrideRes != null)
  {
    bx = overrideRes.x;
    by = overrideRes.y;
  }
  bufferRes = new PVector(width * bx, height * by);
  output = createGraphics( int(bufferRes.x), int(bufferRes.y), P2D);
  println("BUFFER RESOLUTION " + bufferRes);
  
  
  // Populate ships
  sceneShipManager = new ShipManager();
  {
    // PLAYER VESSEL
    // Added first, so it's always on the bottom of the stack
    PVector pos = new PVector(0, 50, 0);
    PVector targetPos = pos.get();
    targetPos.add( new PVector(0, 1, 0) );
    Ship player1 = sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_MANTLE, 1);
    player1.wrap = false;
    player1.navMode = Ship.NAV_MODE_EXTERNAL;
    player1.cloakOnInactive = true;
    player1.invulnerable = true;
    
    playerShip = player1;
  }
  for(int i = 0;  i < MIN_SHIP_COUNT;  i++)
  {
    spawnShipPreyA();
  }
  
  
  // Populate set dressing
  dressageShipManager = new ShipManager();
  int dressCount = 8;
  for(int i = 0;  i < dressCount;  i++)
  {
    PVector pos = new PVector(random(-60,60),  random(0,100),  0.0);
    PVector targetPos = new PVector(random(-60,60),  random(0,100),  0.0);
    Ship s = dressageShipManager.makeShip(pos, targetPos, ShipManager.MODEL_DUST, -1); 
  }
  
  
  // Setup renderers
  hud = new Hud(output);
  
  renderManager = new RenderManager(output);
  renderManager.fullWarp = tex_flatNorm;
  renderManager.doBloom = true;
  renderManager.bForeground = hud.output;
  
  
  
  // Setup constant lights
  sceneLights = new ArrayList();
  // Directional lights
  // Cyan rim light from lower left
  DAGTransform dirlDag = new DAGTransform(0,0,0, 0, 1,1,1);  // Necessary evil
  Light dirl = new Light(dirlDag, 0.2, color(127, 191, 255, 255));
  dirl.makeDirectional( new PVector(0.6, -1, 0.0) );
  sceneLights.add(dirl);
  // Neutral fill from above
  dirl = new Light(dirlDag, 0.1, color(223, 255, 223, 255));
  dirl.makeDirectional( new PVector(-0.3, 0.5, -1.0) );
  sceneLights.add(dirl);
  // Rust rim
  dirl = new Light(dirlDag, 0.05, color(255,191,127, 255));
  dirl.makeDirectional( new PVector(0.5, 0.0, 0.2) );
  sceneLights.add(dirl);
  /*
  // RGB test lights
  DAGTransform dirlDag = new DAGTransform(0,0,0, 0, 1,1,1);  // Necessary evil
  Light dirl = new Light(dirlDag, 0.6, color(255, 0, 0, 255));
  dirl.makeDirectional( new PVector(1.0, 0.0, -0.0) );
  sceneLights.add(dirl);
  dirl = new Light(dirlDag, 0.6, color(0, 255, 0, 255));
  dirl.makeDirectional( new PVector(0.0, 1.0, -0.0) );
  sceneLights.add(dirl);
  dirl = new Light(dirlDag, 0.6, color(0, 0, 255, 255));
  dirl.makeDirectional( new PVector(0, 0, 1.0) );
  sceneLights.add(dirl);
  */
  
  
  
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
  camActive = camConnected;
  motionCursor = new MotionCursor();
  motionCursor.setDrawTarget(hud.output);
  motionCursor.selDrawCam = camConnected;
  motionCursor.run(tex_flatBlack);      // Pretouch systems
  diagnoseBuffers = false;
}
// setup





void draw()
{
  /*
  CONTROL
  */
  
  // Handle camera input
  if(camActive)
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
  //float tick = story.tick;
  float tick = min(2.0, story.tick);  // Frame rate override
  
  
  // Manage scene lights
  Iterator iLights = sceneLights.iterator();
  while( iLights.hasNext() )
  {
    Light l = (Light) iLights.next();
    renderManager.addLight(l);
  }
  
  
  // Smooth simulation
  float simStep = 1.0;
  float simSteps = ceil(tick / simStep);
  
  // Manage set dressing
  for(int i = 0;  i < simSteps;  i++)
  {
    dressageShipManager.run(tick / simSteps);
  }
  
  // Manage ships
  for(int i = 0;  i < simSteps;  i++)
  {
    sceneShipManager.run(tick / simSteps);
  }
  //sceneShipManager.run(tick);
  
  // Render
  dressageShipManager.render(renderManager);
  sceneShipManager.render(renderManager);
  // Manage population
  if(sceneShipManager.ships.size() < MIN_SHIP_COUNT + 1)  // The player is also counted
  {
    if(random(1.0) < 0.5)
    {
      spawnShipPreyA();
    }
    else
    {
      spawnShipPreyB();
    }
    //spawnShipPreyGunboat();
  }
  
  
  // Draw excitement meters and HUD
  // These are hooked onto the renderManager's foreground feed
  hud.drawHUD();
  motionCursor.renderMoVis();
  
  
  // Perform final render
  renderManager.render();
  
  
  /*
  FINAL VISUAL COMPOSIT
  */
  // Unfiltered output
  //image(output, 0,0, width, height);
  // Motion blur version
  pushStyle();
  tint(255, 127);
  image(output, 0,0, width, height);
  popStyle();
  
  
  
  /*
  Diagnostics
  */
  
  // Visualise camera systems
  if(diagnoseBuffers)
  {
    if(camConnected)
    {
      bgLearn.diagnoseBuffers();
      motionCursor.diagnose();
    }
    renderManager.diagnoseBuffers(g);
  }
  
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
  if( key == ' ')
  {
    if(paused)
    {
      loop();
      paused = false;
    }
    else
    {
      noLoop();
      paused = true;
    }
  }
  
  if( key == 'B'  ||  key == 'b' )
  {
    // Toggle bloom effects
    renderManager.doBloom = !renderManager.doBloom;
  }
  
  if( key == 'N'  ||  key == 'n' )
  {
    // Toggle low resolution: this will RESTART THE PROGRAM
    if(overrideRes == null)
    {
      overrideRes = new PVector(0.5, 0.5);
    }
    else if(overrideRes.x == 0.5)
    {
      overrideRes.set(1.0, 1.0);
    }
    else
    {
      overrideRes.set(0.5, 0.5);
    }
    setup();
  }
  
  if( key == 'S'  ||  key == 's' )
  {
    save("screenshots/MantleScreenshot_" + year() + nf(month(), 2) + nf(day(), 2) 
      + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + "_" + millis() + ".jpg");
  }
  
  if( (key == '~'  ||  key == '`'))  {  diagnoseBuffers = !diagnoseBuffers;  }
  
  if(camConnected)
  {
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
    
    // Disable camera
    if( key == 'M'  ||  key == 'm' )
    {
      if(camActive)
      {
        cam.stop();
        camActive = false;
      }
      else
      {
        cam.start();
        camActive = true;
      }
      motionCursor.selDrawCam = camActive;
    }
  }
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
  PVector pos = new PVector(random(-60,60), -4, 0);
  PVector targetPos = pos.get();
  targetPos.add( PVector.random3D() );
  sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_PREY_A, 0);
}

void spawnShipPreyB()
{
  PVector pos = new PVector(random(-60,60), -4, 0);
  PVector targetPos = pos.get();
  targetPos.add( PVector.random3D() );
  sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_PREY_B, 0);
}

void spawnShipPreyGunboat()
{
  PVector pos = new PVector(random(-60,60), -4, 0);
  PVector targetPos = pos.get();
  targetPos.add( PVector.random3D() );
  Ship s = sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_GUNBOAT, 0);
  s.navMode = s.NAV_MODE_AVOID;
}


PGraphics loadImageScaled(String filename, float scalefactor)
// Loads an image scaled. Very useful for getting better performance from the high-res assets used in Mantle.
{
  PImage img = loadImage(filename);
  int resX = int(img.width * scalefactor);
  int resY = int(img.height * scalefactor);
  resX = min(resX, img.width);
  resX = min(resY, img.height);
  PGraphics pg = createGraphics(resX, resY, P2D);
  pg.beginDraw();
  pg.clear();
  pg.image(img, 0,0, pg.width, pg.height);
  pg.endDraw();
  return( pg );
}
// loadImageScaled




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
