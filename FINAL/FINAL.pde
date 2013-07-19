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
  frameRate(30);                    // Because it's plenty smooth at 30 and 15 is too low
  
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
  font = loadFont("DroidSans-18.vlw");
  textFont(font);
  
  lightStencil = loadImage("images/lightStencil16.png");
  
  tex_backdrop = loadImage("images/starscape3.png");
  tex_warpBackdrop = loadImage("images/windowGlass5.png");
  
  fx_shockwave = loadImage("images/effects/shockwave2.png");
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
  fx_wrinkle8 = loadImage("images/effects/wrinkle8.png");
  fx_wrinkle64 = loadImage("images/effects/wrinkle64.png");
  fx_wrinkle256 = loadImage("images/effects/wrinkle256.png");
  
  hud_reticule = loadImage("images/hud/HUDreticule.png");
  hud_element_helm = loadImage("images/hud/HUD_elements_helm.png");
  hud_element_offline = loadImage("images/hud/HUD_elements_offline.png");
  hud_element_online = loadImage("images/hud/HUD_elements_online.png");
  hud_element_stealth = loadImage("images/hud/HUD_elements_stealth.png");
  
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
  ship_preya_turret_diff = loadImage("images/ships/PreyA/PreyA_turret_diff.png");
  ship_preya_turret_norm = loadImage("images/ships/PreyA/PreyA_turret_norm.png");
  
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
  ship_preya_turret_warp = loadImage("images/ships/PreyA/PreyA_turret_warp.png");
  /*
  ship_preya_bridge_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_bridge_norm.png"),  "PreyA_bridge_warp" );
  ship_preya_drive_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_drive_norm.png"),  "PreyA_drive_warp" );
  ship_preya_inner_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_inner_norm.png"),  "PreyA_inner_warp" );
  ship_preya_motor1L_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_motor1L_norm.png"),  "PreyA_motor1L_warp" );
  ship_preya_motor1R_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_motor1R_norm.png"),  "PreyA_motor1R_warp" );
  ship_preya_motor2L_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_motor2L_norm.png"),  "PreyA_motor2L_warp" );
  ship_preya_motor2R_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_motor2R_norm.png"),  "PreyA_motor2R_warp" );
  ship_preya_motor3L_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_motor3L_norm.png"),  "PreyA_motor3L_warp" );
  ship_preya_motor3R_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_motor3R_norm.png"),  "PreyA_motor3R_warp" );
  ship_preya_prow_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_prow_norm.png"),  "PreyA_prow_warp" );
  ship_preya_thrusterArmL_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_thrusterArmL_norm.png"),  "PreyA_thrusterArmL_warp" );
  ship_preya_thrusterArmR_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_thrusterArmR_norm.png"),  "PreyA_thrusterArmR_warp" );
  ship_preya_thrusterL_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_thrusterL_norm.png"),  "PreyA_thrusterL_warp" );
  ship_preya_thrusterR_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_thrusterR_norm.png"),  "PreyA_thrusterR_warp" );
  ship_preya_turret_warp = normalToWarp( loadImage("images/ships/PreyA/PreyA_turret_norm.png"),  "PreyA_turret_warp" );
  */
  
  // LoadMantle ship sprites
  ship_mantle_keel_diff = loadImage("images/ships/Mantle/Mantle_keel_diff.png");
  ship_mantle_keel_norm = loadImage("images/ships/Mantle/Mantle_keel_norm.png");
  ship_mantle_keel_warp = loadImage("images/ships/Mantle/Mantle_keel_warp.png");
  ship_mantle_tail1_diff = loadImage("images/ships/Mantle/Mantle_tail1_diff.png");
  ship_mantle_tail1_norm = loadImage("images/ships/Mantle/Mantle_tail1_norm.png");
  ship_mantle_tail1_warp = loadImage("images/ships/Mantle/Mantle_tail1_warp.png");
  ship_mantle_tail2_diff = loadImage("images/ships/Mantle/Mantle_tail2_diff.png");
  ship_mantle_tail2_norm = loadImage("images/ships/Mantle/Mantle_tail2_norm.png");
  ship_mantle_tail2_warp = loadImage("images/ships/Mantle/Mantle_tail2_warp.png");
  ship_mantle_tail3_diff = loadImage("images/ships/Mantle/Mantle_tail3_diff.png");
  ship_mantle_tail3_norm = loadImage("images/ships/Mantle/Mantle_tail3_norm.png");
  ship_mantle_tail3_warp = loadImage("images/ships/Mantle/Mantle_tail3_warp.png");
  ship_mantle_tailL1_diff = loadImage("images/ships/Mantle/Mantle_tailL1_diff.png");
  ship_mantle_tailL1_norm = loadImage("images/ships/Mantle/Mantle_tailL1_norm.png");
  ship_mantle_tailL1_warp = loadImage("images/ships/Mantle/Mantle_tailL1_warp.png");
  ship_mantle_tailL2_diff = loadImage("images/ships/Mantle/Mantle_tailL2_diff.png");
  ship_mantle_tailL2_norm = loadImage("images/ships/Mantle/Mantle_tailL2_norm.png");
  ship_mantle_tailL2_warp = loadImage("images/ships/Mantle/Mantle_tailL2_warp.png");
  ship_mantle_tailL3_diff = loadImage("images/ships/Mantle/Mantle_tailL3_diff.png");
  ship_mantle_tailL3_norm = loadImage("images/ships/Mantle/Mantle_tailL3_norm.png");
  ship_mantle_tailL3_warp = loadImage("images/ships/Mantle/Mantle_tailL3_warp.png");
  ship_mantle_tailR1_diff = loadImage("images/ships/Mantle/Mantle_tailR1_diff.png");
  ship_mantle_tailR1_norm = loadImage("images/ships/Mantle/Mantle_tailR1_norm.png");
  ship_mantle_tailR1_warp = loadImage("images/ships/Mantle/Mantle_tailR1_warp.png");
  ship_mantle_tailR2_diff = loadImage("images/ships/Mantle/Mantle_tailR2_diff.png");
  ship_mantle_tailR2_norm = loadImage("images/ships/Mantle/Mantle_tailR2_norm.png");
  ship_mantle_tailR2_warp = loadImage("images/ships/Mantle/Mantle_tailR2_warp.png");
  ship_mantle_tailR3_diff = loadImage("images/ships/Mantle/Mantle_tailR3_diff.png");
  ship_mantle_tailR3_norm = loadImage("images/ships/Mantle/Mantle_tailR3_norm.png");
  ship_mantle_tailR3_warp = loadImage("images/ships/Mantle/Mantle_tailR3_warp.png");
  ship_mantle_tailTip_diff = loadImage("images/ships/Mantle/Mantle_tailTip_diff.png");
  ship_mantle_tailTip_norm = loadImage("images/ships/Mantle/Mantle_tailTip_norm.png");
  ship_mantle_tailTip_warp = loadImage("images/ships/Mantle/Mantle_tailTip_warp.png");
  ship_mantle_turret_diff = loadImage("images/ships/Mantle/Mantle_turret_diff.png");
  ship_mantle_turret_norm = loadImage("images/ships/Mantle/Mantle_turret_norm.png");
  ship_mantle_turret_warp = loadImage("images/ships/Mantle/Mantle_turret_warp.png");
  ship_mantle_wing1L_diff = loadImage("images/ships/Mantle/Mantle_wing1L_diff.png");
  ship_mantle_wing1L_norm = loadImage("images/ships/Mantle/Mantle_wing1L_norm.png");
  ship_mantle_wing1L_warp = loadImage("images/ships/Mantle/Mantle_wing1L_warp.png");
  ship_mantle_wing1R_diff = loadImage("images/ships/Mantle/Mantle_wing1R_diff.png");
  ship_mantle_wing1R_norm = loadImage("images/ships/Mantle/Mantle_wing1R_norm.png");
  ship_mantle_wing1R_warp = loadImage("images/ships/Mantle/Mantle_wing1R_warp.png");
  ship_mantle_wing2L_diff = loadImage("images/ships/Mantle/Mantle_wing2L_diff.png");
  ship_mantle_wing2L_norm = loadImage("images/ships/Mantle/Mantle_wing2L_norm.png");
  ship_mantle_wing2L_warp = loadImage("images/ships/Mantle/Mantle_wing2L_warp.png");
  ship_mantle_wing2R_diff = loadImage("images/ships/Mantle/Mantle_wing2R_diff.png");
  ship_mantle_wing2R_norm = loadImage("images/ships/Mantle/Mantle_wing2R_norm.png");
  ship_mantle_wing2R_warp = loadImage("images/ships/Mantle/Mantle_wing2R_warp.png");
  
  // Load debris sprites
  debris_01_diff = loadImage("images/effects/debris/debris01_diff.png");
  debris_01_norm = loadImage("images/effects/debris/debris01_norm.png");
  debris_02_diff = loadImage("images/effects/debris/debris02_diff.png");
  debris_02_norm = loadImage("images/effects/debris/debris02_norm.png");
  debris_03_diff = loadImage("images/effects/debris/debris03_diff.png");
  debris_03_norm = loadImage("images/effects/debris/debris03_norm.png");
  debris_04_diff = loadImage("images/effects/debris/debris04_diff.png");
  debris_04_norm = loadImage("images/effects/debris/debris04_norm.png");
  debris_05_diff = loadImage("images/effects/debris/debris05_diff.png");
  debris_05_norm = loadImage("images/effects/debris/debris05_norm.png");
  debris_06_diff = loadImage("images/effects/debris/debris06_diff.png");
  debris_06_norm = loadImage("images/effects/debris/debris06_norm.png");
  debris_07_diff = loadImage("images/effects/debris/debris07_diff.png");
  debris_07_norm = loadImage("images/effects/debris/debris07_norm.png");
  debris_08_diff = loadImage("images/effects/debris/debris08_diff.png");
  debris_08_norm = loadImage("images/effects/debris/debris08_norm.png");
  debris_09_diff = loadImage("images/effects/debris/debris09_diff.png");
  debris_09_norm = loadImage("images/effects/debris/debris09_norm.png");
  
  debris_10_diff = loadImage("images/effects/debris/debris10_diff.png");
  debris_10_norm = loadImage("images/effects/debris/debris10_norm.png");
  debris_11_diff = loadImage("images/effects/debris/debris11_diff.png");
  debris_11_norm = loadImage("images/effects/debris/debris11_norm.png");
  debris_12_diff = loadImage("images/effects/debris/debris12_diff.png");
  debris_12_norm = loadImage("images/effects/debris/debris12_norm.png");
  debris_13_diff = loadImage("images/effects/debris/debris13_diff.png");
  debris_13_norm = loadImage("images/effects/debris/debris13_norm.png");
  debris_14_diff = loadImage("images/effects/debris/debris14_diff.png");
  debris_14_norm = loadImage("images/effects/debris/debris14_norm.png");
  debris_15_diff = loadImage("images/effects/debris/debris15_diff.png");
  debris_15_norm = loadImage("images/effects/debris/debris15_norm.png");
  debris_16_diff = loadImage("images/effects/debris/debris16_diff.png");
  debris_16_norm = loadImage("images/effects/debris/debris16_norm.png");
  debris_17_diff = loadImage("images/effects/debris/debris17_diff.png");
  debris_17_norm = loadImage("images/effects/debris/debris17_norm.png");
  debris_18_diff = loadImage("images/effects/debris/debris18_diff.png");
  debris_18_norm = loadImage("images/effects/debris/debris18_norm.png");
  debris_19_diff = loadImage("images/effects/debris/debris19_diff.png");
  debris_19_norm = loadImage("images/effects/debris/debris19_norm.png");
  
  debris_20_diff = loadImage("images/effects/debris/debris20_diff.png");
  debris_20_norm = loadImage("images/effects/debris/debris20_norm.png");
  debris_21_diff = loadImage("images/effects/debris/debris21_diff.png");
  debris_21_norm = loadImage("images/effects/debris/debris21_norm.png");
  debris_22_diff = loadImage("images/effects/debris/debris22_diff.png");
  debris_22_norm = loadImage("images/effects/debris/debris22_norm.png");
  debris_23_diff = loadImage("images/effects/debris/debris23_diff.png");
  debris_23_norm = loadImage("images/effects/debris/debris23_norm.png");
  debris_24_diff = loadImage("images/effects/debris/debris24_diff.png");
  debris_24_norm = loadImage("images/effects/debris/debris24_norm.png");
  
  debris_dust = loadImage("images/effects/debris/SpaceDust.png");
  
  
  // Setup story
  story = new Story();
  
  // Setup pause management
  paused = false;
  
  
  // Setup draw buffer
  bufferRes = new PVector(width, height);
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
  int dressCount = 16;
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
  // Blue rim light from lower left
  DAGTransform dirlDag = new DAGTransform(0,0,0, 0, 1,1,1);  // Necessary evil
  Light dirl = new Light(dirlDag, 0.2, color(127, 191, 255, 255));
  dirl.makeDirectional( new PVector(0.6, -1, 0.0) );
  sceneLights.add(dirl);
  // Neutral fill from above
  dirl = new Light(dirlDag, 0.1, color(255, 255));
  dirl.makeDirectional( new PVector(0.3, 1.0, -0.5) );
  sceneLights.add(dirl);
  // Blue rim
  dirl = new Light(dirlDag, 0.3, color(191,191,255, 255));
  dirl.makeDirectional( new PVector(-0.5, 0.2, 1.0) );
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
  float tick = 2.0;  // Frame rate override
  
  
  // Manage scene lights
  Iterator iLights = sceneLights.iterator();
  while( iLights.hasNext() )
  {
    Light l = (Light) iLights.next();
    renderManager.addLight(l);
  }
  
  
  // Smooth simulation
  float simStep = 0.5;
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
    spawnShipPreyA();
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

void spawnShipPreyGunboat()
{
  PVector pos = new PVector(random(-60,60), -4, 0);
  PVector targetPos = pos.get();
  targetPos.add( PVector.random3D() );
  Ship s = sceneShipManager.makeShip(pos, targetPos, ShipManager.MODEL_GUNBOAT, 0);
  s.navMode = s.NAV_MODE_AVOID;
}


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
