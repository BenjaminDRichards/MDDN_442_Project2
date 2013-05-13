import java.util.*;

class Story
/*

Control system for the events that occur.

A way to hide all the complex setup from the main program,
then schedule interesting things to happen.

Includes time management.

*/
{
  // Where the work gets done
  ParticleManager pManager;
  
  // Event manager
  ArrayList storyEvents;
  
  // Time parameters
  int timeMode;      // 0 = realtime, 1 = render every frame
  float lastTickCount, thisTickCount;
  float idealFrameRate;
  float tick;
  float tickTotal;
  boolean pause;
  
  float TIMESKIP = 2;           // Number of frames to advance per iteration
                                //  Don't set to 0!
  float START_OFFSET = 0;       // Fast-forward the beginning
  
  // Asset tracking
  Ship ship1, ship2, ship3, ship3calf;
  ArrayList bombardment1, bombardment2, bombardment3;
  
  // Graphics
  
  // Standard hulls
  PImage image_hull1_diff = loadImage("ship2_series6_diff.png");
  PImage image_hull1_norm = loadImage("ship2_series6_norm.png");
  PImage image_hull1_coll = loadImage("ship2_series6_coll.png");
  
  PImage image_hull2_diff = loadImage("ship2_series6_diff_256.png");
  PImage image_hull2_norm = loadImage("ship2_series6_norm_256.png");
  PImage image_hull2_coll = loadImage("ship2_series6_coll_256.png");
  
  PImage image_hull3_diff = loadImage("ship2_series6_diff_512.png");
  PImage image_hull3_norm = loadImage("ship2_series6_norm_512.png");
  PImage image_hull3_coll = loadImage("ship2_series6_coll_512.png");
  
  // Breakable hulls
  /*
  PImage image_hull3_break_main_diff = loadImage("ship2_series6_BREAK_MAIN_DIFF_256.png");
  PImage image_hull3_break_main_norm = loadImage("ship2_series6_BREAK_MAIN_NORM_256.png");
  PImage image_hull3_break_main_coll = loadImage("ship2_series6_BREAK_MAIN_COLL_256.png");
  
  PImage image_hull3_break_calf_diff = loadImage("ship2_series6_BREAK_CALF_DIFF_256.png");
  PImage image_hull3_break_calf_norm = loadImage("ship2_series6_BREAK_CALF_NORM_256.png");
  PImage image_hull3_break_calf_coll = loadImage("ship2_series6_BREAK_CALF_COLL_256.png");
  */
  PImage image_hull3_break_main_diff = loadImage("ship2_series6_BREAK_MAIN_DIFF.png");
  PImage image_hull3_break_main_norm = loadImage("ship2_series6_BREAK_MAIN_NORM_256.png");
  PImage image_hull3_break_main_coll = loadImage("ship2_series6_BREAK_MAIN_COLL.png");
  
  PImage image_hull3_break_calf_diff = loadImage("ship2_series6_BREAK_CALF_DIFF.png");
  PImage image_hull3_break_calf_norm = loadImage("ship2_series6_BREAK_CALF_NORM_256.png");
  PImage image_hull3_break_calf_coll = loadImage("ship2_series6_BREAK_CALF_COLL.png");
  
  // Impact assets
  PImage image_smoke = loadImage("smokePuff2.png");
  PImage image_smokeB = loadImage("smokePuff2B.png");
  PImage image_spark = loadImage("blast3.png");
  PImage image_chunk = loadImage("DebrisChunk.png");
  
  // Scale for lowres texture paradigms
  float TEX_SCALE = 1.5;
  
  
  
  
  Story(ParticleManager pManager)
  {
    this.pManager = pManager;
    
    storyEvents = new ArrayList();
    
    // Setup story
    setupStory();
    
    // Setup time
    timeMode = 1;
    idealFrameRate = 60;
    thisTickCount = 0.0;
    lastTickCount = -1.0;
    tick = 1;
    tickTotal = 0;
    pause = false;
  }
  
  
  void run()
  // Execute decisions
  {
    // Manage time
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
    if(frameCount < 4)  tickTotal = frameCount;
    
    // Check story events
    Iterator i = storyEvents.iterator();
    while( i.hasNext() )
    {
      StoryEvent se = (StoryEvent) i.next();
      if(se.isTriggered(tickTotal + START_OFFSET))
      {
        // Update time and check if time trigger occurs
        command(se.commandCode);
        i.remove();
      }
    }
  }
  // run
  
  
  void setupStory()
  // Script the sequence of events
  {
    // This story is set to Introitus, Mozart's Requiem Mass in D Minor
    
    // We begin in empty space, a planet below.
    
    // Create environment lights
    makeEvent(1, 101);
    
    // Introduce a ship
    makeEvent(1200, 111);
    
    // The music develops excitement
    
    // Shoot at the ship
    makeEvent(2100, 171);
    makeEvent(2700, 172);
    
    // The music turns tragic
    
    // Introduce another ship, aflame
    makeEvent(2000, 112);
    
    // Intensify bombardment
    makeEvent(3300, 173);
    
    // Introduce hero ship
    makeEvent(3600, 113);
    
    // The music turns quiet and sorrowful
    
    // Break hero ship
    makeEvent(6000, 121);
    makeEvent(6020, 122);
    makeEvent(6040, 123);
    makeEvent(6080, 124);
    
    // The music goes through a heroic interval
    
    // Shut down bombardment
    makeEvent(7500, 181);
    makeEvent(8500, 182);
    makeEvent(9500, 183);
    
    // The music reaches a natural stopping point at 3:05
    makeEvent(11100, 999);
  }
  // setupStory
  
  
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
    
    // Setup lights
    if(code == 101)  cmd_setupLights();
    
    // Setup ships
    if(code == 111)  cmd_setupShip1();
    if(code == 112)  cmd_setup_ship2();
    if(code == 113)  cmd_setup_ship3();
    
    // Control ships
    if(code == 121)  cmd_shatter_ship3();
    if(code == 122)  cmd_shatter_ship3_stage2();
    if(code == 123)  cmd_shatter_ship3_stage3();
    if(code == 124)  cmd_shatter_ship3_stage4();
    
    // Setup bombardment
    if(code == 171)  cmd_setup_bombardment1();
    if(code == 172)  cmd_setup_bombardment2();
    if(code == 173)  cmd_setup_bombardment3();
    
    // Teardown bombardment
    if(code == 181)  cmd_teardown_bombardment1();
    if(code == 182)  cmd_teardown_bombardment2();
    if(code == 183)  cmd_teardown_bombardment3();
    
    // Program control
    if(code == 999)  cmd_program_end();
  }
  // command
  
  
  void cmd_setupLights()
  // CODE 101
  // Initialise some constant lights
  {
    println("CODE 101: Setting up lights...");
    
    // Sky lights
    
    // Sky 1: Bright solar rim
    Light skyLight1 = new Light(width,0, height * 0.5,  1,-1,0.5,  color(255,222,192),  2.0, 1, 0);
    pManager.addLight(skyLight1);
    
    // Sky 2: Underlit atmospheric glow
    Light skyLight2 = new Light(width,0, height * 0.5,  0.5,1,-0.5,  color(192,222,255),  0.5, 1, 0);
    pManager.addLight(skyLight2);
  }
  // cmd_setupLights
  
  
  void cmd_setupShip1()
  // CODE 111
  // Insert an initial ship
  {
    // Ship geometry
    
    ship1 = new Ship(2500, 1300, 0,  -1, -0.5, 0,  image_hull3_diff, image_hull2_norm );
    ship1.trail = true;
    ship1.loadStencil(image_hull3_coll);
    ship1.scalar = 0.5 * TEX_SCALE;
    ship1.id = #ff0111;
    pManager.addShip(ship1);
    
    // Ship drives
    
    Emitter_Drive ed1 = new Emitter_Drive(-9999,0,0,  0,0,0,  image_null,  pManager);
    ship1.addEmitter(ed1, new PVector(16 / TEX_SCALE, 160 / TEX_SCALE, 1));
    pManager.addEmitter(ed1);
    
    Emitter_Drive ed2 = new Emitter_Drive(-9999,0,0,  0,0,0,  image_null,  pManager);
    ship1.addEmitter(ed2, new PVector(-16 / TEX_SCALE, 160 / TEX_SCALE, 1));
    pManager.addEmitter(ed2);
  }
  // cmd_setupShip1
  
  
  void cmd_setup_ship2()
  // CODE 112
  // Insert a tumbling ship
  {
    // Ship geometry
    
    ship2 = new Ship(2500, -512, 0,  -1, 0.8, 0,  image_hull3_diff, image_hull2_norm );
    ship2.ang.set(0, 0, -QUARTER_PI);
    ship2.angVel.set(0,0, -0.004);
    ship2.loadStencil(image_hull3_coll);
    ship2.scalar = 0.6 * TEX_SCALE;
    ship2.id = #fe0112;
    pManager.addShip(ship2);
    
    // Ship death throes
    // Impact emitters set to never die
    
    Emitter_Impact ei1 = new Emitter_Impact(-9999,0,0,  0,0,0,  image_null,  pManager);
    ei1.emitDecayMax = 0;
    ship2.addEmitter(ei1, new PVector(0 / TEX_SCALE, 160 / TEX_SCALE, 1) );
    pManager.addEmitter(ei1);
    
    Emitter_Impact ei2 = new Emitter_Impact(-9999,0,0,  0,0,0,  image_null,  pManager);
    ei2.emitDecayMax = 0;
    ship2.addEmitter(ei2, new PVector(64 / TEX_SCALE, 32 / TEX_SCALE, 1) );
    pManager.addEmitter(ei2);
    
    Emitter_Impact ei3 = new Emitter_Impact(-9999,0,0,  0,0,0,  image_null,  pManager);
    ei3.emitDecayMax = 0;
    ship2.addEmitter(ei3, new PVector(-32 / TEX_SCALE, -127 / TEX_SCALE, 1) );
    pManager.addEmitter(ei3);
  }
  // cmd_setup_ship2
  
  
  void cmd_setup_ship3()
  // CODE 113
  // Insert the hero ship
  {
    // Ship geometry
    
    ship3 = new Ship(2500, 0, 0,  -0.5, 0.18, 0,  image_hull3_diff, image_hull2_norm );
    ship3.trail = true;
    ship3.loadStencil(image_hull3_coll);
    ship3.scalar = 1.0 * TEX_SCALE;
    ship3.id = #fd0113;
    pManager.addShip(ship3);
    
    
    // Ship drives
    
    Emitter_Drive ed1 = new Emitter_Drive(-9999,0,0,  0,0,0,  image_null,  pManager);
    ship3.addEmitter(ed1, new PVector(-16 / TEX_SCALE, 160 / TEX_SCALE, 1));
    pManager.addEmitter(ed1);
    
    Emitter_Drive ed2 = new Emitter_Drive(-9999,0,0,  0,0,0,  image_null,  pManager);
    ship3.addEmitter(ed2, new PVector(16 / TEX_SCALE, 160 / TEX_SCALE, 1));
    pManager.addEmitter(ed2);
    
    
    // Impact emitters set to never die
    
    Emitter_Impact ei1 = new Emitter_Impact(-9999,0,0,  0,0,0,  image_null,  pManager);
    ei1.emitDecayMax = 0;
    ship3.addEmitter(ei1, new PVector(64 / TEX_SCALE, -128 / TEX_SCALE, 1) );
    pManager.addEmitter(ei1);
    
    
    // Ship weapons
    
    Emitter_Shooter_Green esg1 = new Emitter_Shooter_Green(-9999, 0, 0,  0, 0, 0,  image_null, pManager);
    esg1.aim.set(-1, 0.5, 0.2);
    ship3.addEmitter( esg1, new PVector(50 / TEX_SCALE, 128 / TEX_SCALE, 4) );
    pManager.addEmitter(esg1);
    
    Emitter_Shooter_Green esg2 = new Emitter_Shooter_Green(-9999, 0, 0,  0, 0, 0,  image_null, pManager);
    esg2.aim.set(-1, 0.5, 0.2);
    ship3.addEmitter( esg2, new PVector(-75 / TEX_SCALE, 96 / TEX_SCALE, 4) );
    pManager.addEmitter(esg2);
    
  }
  // cmd_setup_ship3
  
  
  void cmd_shatter_ship3()
  // CODE 121
  // Break the hero ship in two
  {
    // Replace ship3 graphics
    ship3.img = image_hull3_break_main_diff;
    ship3.normalMap.map = image_hull3_break_main_norm;
    ship3.collStencil = image_hull3_break_main_coll;
    
    // Modify ship3 behaviour
    ship3.trail = false;
    ship3.angVel.set(0,0, -0.0005);
    ship3.vel.add(0.05, 0.05, 0);
    
    // Create the calf
    ship3calf = new Ship(ship3.pos.x, ship3.pos.y, ship3.pos.z - 8,  ship3.vel.x - 0.2, ship3.vel.y - 0.2, 0,
      image_hull3_break_calf_diff, image_hull3_break_calf_norm );
    ship3calf.scalar = 1.0 * TEX_SCALE;
    ship3calf.loadStencil(image_hull3_break_calf_coll);
    ship3calf.id = #fc0121;
    ship3calf.ang = ship3.ang.get();
    ship3calf.angVel = ship3.angVel.get();
    ship3calf.angVel.mult(-3);
    pManager.addShip(ship3calf);
    
    // Create impact emitters along shear line
    // Coords are to be offset by -256,-256
    ArrayList shearEmitters = new ArrayList();
    shearEmitters.add(new PVector(248,-10,0) );
    //shearEmitters.add(new PVector(243,20,0) );
    shearEmitters.add(new PVector(235,45,0) );
    //shearEmitters.add(new PVector(228,67,0) );
    //shearEmitters.add(new PVector(242,80,0) );
    //shearEmitters.add(new PVector(228,96,0) );
    shearEmitters.add(new PVector(236,117,0) );
    //shearEmitters.add(new PVector(233,158,0) );
    //shearEmitters.add(new PVector(246,160,0) );
    //shearEmitters.add(new PVector(254,212,0) );
    //shearEmitters.add(new PVector(273,251,0) );
    shearEmitters.add(new PVector(308,279,0) );
    //shearEmitters.add(new PVector(318,292,0) );
    
    Iterator i = shearEmitters.iterator();
    while( i.hasNext() )
    {
      PVector coord = (PVector) i.next();
      coord.sub(256,256,0);
      ship3_addShearEmitter(coord);
    }
  }
  // cmd_shatter_ship3
  
  
  void cmd_shatter_ship3_stage2()
  // CODE 122
  // Adds more impact emitters
  {
    ArrayList shearEmitters = new ArrayList();
    //shearEmitters.add(new PVector(248,-10,0) );
    //shearEmitters.add(new PVector(243,20,0) );
    //shearEmitters.add(new PVector(235,45,0) );
    //shearEmitters.add(new PVector(228,67,0) );
    shearEmitters.add(new PVector(242,80,0) );
    shearEmitters.add(new PVector(228,96,0) );
    //shearEmitters.add(new PVector(236,117,0) );
    shearEmitters.add(new PVector(233,158,0) );
    //shearEmitters.add(new PVector(246,160,0) );
    //shearEmitters.add(new PVector(254,212,0) );
    shearEmitters.add(new PVector(273,251,0) );
    //shearEmitters.add(new PVector(308,279,0) );
    //shearEmitters.add(new PVector(318,292,0) );
    
    Iterator i = shearEmitters.iterator();
    while( i.hasNext() )
    {
      PVector coord = (PVector) i.next();
      coord.sub(256,256,0);
      ship3_addShearEmitter(coord);
    }
  }
  // cmd_shatter_ship3_stage2
  
  
  void cmd_shatter_ship3_stage3()
  // CODE 123
  // Adds more impact emitters
  {
    ArrayList shearEmitters = new ArrayList();
    //shearEmitters.add(new PVector(248,-10,0) );
    shearEmitters.add(new PVector(243,20,0) );
    //shearEmitters.add(new PVector(235,45,0) );
    //shearEmitters.add(new PVector(228,67,0) );
    //shearEmitters.add(new PVector(242,80,0) );
    shearEmitters.add(new PVector(228,96,0) );
    //shearEmitters.add(new PVector(236,117,0) );
    //shearEmitters.add(new PVector(233,158,0) );
    //shearEmitters.add(new PVector(246,160,0) );
    shearEmitters.add(new PVector(254,212,0) );
    //shearEmitters.add(new PVector(273,251,0) );
    //shearEmitters.add(new PVector(308,279,0) );
    //shearEmitters.add(new PVector(318,292,0) );
    
    Iterator i = shearEmitters.iterator();
    while( i.hasNext() )
    {
      PVector coord = (PVector) i.next();
      coord.sub(256,256,0);
      ship3_addShearEmitter(coord);
    }
  }
  // cmd_shatter_ship3_stage3
  
  
  void cmd_shatter_ship3_stage4()
  // CODE 124
  // Adds more impact emitters
  {
    ArrayList shearEmitters = new ArrayList();
    //shearEmitters.add(new PVector(248,-10,0) );
    //shearEmitters.add(new PVector(243,20,0) );
    //shearEmitters.add(new PVector(235,45,0) );
    //shearEmitters.add(new PVector(228,67,0) );
    //shearEmitters.add(new PVector(242,80,0) );
    //shearEmitters.add(new PVector(228,96,0) );
    //shearEmitters.add(new PVector(236,117,0) );
    //shearEmitters.add(new PVector(233,158,0) );
    shearEmitters.add(new PVector(246,160,0) );
    //shearEmitters.add(new PVector(254,212,0) );
    //shearEmitters.add(new PVector(273,251,0) );
    //shearEmitters.add(new PVector(308,279,0) );
    shearEmitters.add(new PVector(318,292,0) );
    
    Iterator i = shearEmitters.iterator();
    while( i.hasNext() )
    {
      PVector coord = (PVector) i.next();
      coord.sub(256,256,0);
      ship3_addShearEmitter(coord);
    }
  }
  // cmd_shatter_ship3_stage4
  
  
  void ship3_addShearEmitter(PVector coord)
  // Adds a shear emitter to ship3 and its calf
  {
    // Main version
    Emitter_Impact ei = new Emitter_Impact(-9999,0,0,  0,0,0,  image_null,  pManager);
    ship3.addEmitter(ei, new PVector(coord.x / TEX_SCALE, coord.y / TEX_SCALE, 1) );
    pManager.addEmitter(ei);
    // Calf duplicate
    ei = new Emitter_Impact(-9999,0,0,  0,0,0,  image_null,  pManager);
    ship3calf.addEmitter(ei, new PVector(coord.x / TEX_SCALE, coord.y / TEX_SCALE, 1) );
    pManager.addEmitter(ei);
    // Do impact
    doImpact(pManager, ei.pos);
  }
  // ship3_addShearEmitter
  
  
  void cmd_setup_bombardment1()
  // CODE 171
  // Insert a set of enemy shot emitters
  {
    bombardment1 = new ArrayList();
    
    for(int i = 0;  i < 3;  i++)
    {
      Emitter_Shooter emShoot = new Emitter_Shooter(384 * i, 1250 + sin(i) * 256, 64,  0,0,0, image_null, pManager);
      emShoot.aim = new PVector(cos(-i * 3 + 1), -0.5, 0);
      emShoot.emitVel *= 1 + 0.5 * sin(emShoot.pos.x);
      
      pManager.addEmitter(emShoot);
      
      bombardment1.add(emShoot);
    }
  }
  // cmd_setup_bombardment1
  
  
  void cmd_setup_bombardment2()
  // CODE 172
  // Insert a set of enemy shot emitters
  {
    bombardment2 = new ArrayList();
    
    for(int i = 0;  i < 4;  i++)
    {
      Emitter_Shooter emShoot = new Emitter_Shooter(256 * (i + 2), 1250 + sin(i) * 256, 64,  0,0,0, image_null, pManager);
      emShoot.aim = new PVector(sin(i * 3 + 1), -1, 0);
      emShoot.emitVel *= 1 + 0.5 * sin(emShoot.pos.x);
      
      pManager.addEmitter(emShoot);
      
      bombardment2.add(emShoot);
    }
  }
  // cmd_setup_bombardment2
  
  
  void cmd_setup_bombardment3()
  // CODE 173
  // Insert a set of enemy shot emitters
  {
    bombardment3 = new ArrayList();
    
    for(int i = 0;  i < 4;  i++)
    {
      Emitter_Shooter emShoot = new Emitter_Shooter(256 * (i - 8), -500 + sin(i * 3) * 256, 64,  0,0,0, image_null, pManager);
      emShoot.aim = new PVector(sin(i * 3 + 1) + 2, 0.75, 0);
      emShoot.emitVel *= 1 + 0.5 * sin(emShoot.pos.x);
      
      pManager.addEmitter(emShoot);
      
      bombardment3.add(emShoot);
    }
  }
  // cmd_setup_bombardment3
  
  
  void teardown_bombardment_list(ArrayList bmlist)
  // Remove listed objects from particle manager
  {
    Iterator i = bmlist.iterator();
    while( i.hasNext() )
    {
      Emitter e = (Emitter) i.next();
      pManager.removeEmitter(e);
    }
  }
  // teardown_bombardment_list
  
  
  void cmd_teardown_bombardment1()
  // CODE 181
  // Stop bombardment from target emitters
  {
    teardown_bombardment_list(bombardment1);
  }
  // cmd_teardown_bombardment1
  
  
  void cmd_teardown_bombardment2()
  // CODE 182
  // Stop bombardment from target emitters
  {
    teardown_bombardment_list(bombardment2);
  }
  // cmd_teardown_bombardment2
  
  
  void cmd_teardown_bombardment3()
  // CODE 183
  // Stop bombardment from target emitters
  {
    teardown_bombardment_list(bombardment3);
  }
  // cmd_teardown_bombardment3
  
  
  void cmd_program_end()
  // CODE 999
  // Ends the program at the appointed time
  {
    exit();
  }
  // cmd_program_end
  
  
  
  void doImpact(ParticleManager pm, PVector pos)
  // Visual effects for initial impact
  {
    // Smoke
    for(int j = 0;  j < 128;  j++)
    {
      // Create particle
      // Exact parameters might need tweaking
      float rSpd = 2;
      PVector rDir = new PVector(1,0);
      rDir.rotate(random(TWO_PI));
      rDir.mult(pow(random(1.0), 3) * rSpd);
      PImage pimg = (random(1.0) < 0.5)  ?  image_smoke  :  image_smokeB;
      ParticleSpriteDecay psd = new ParticleSpriteDecay(pos.x, pos.y, pos.z,
        rDir.x, rDir.y, random(10),
        pimg, color(255,16,192, 16), color(255,255,16) );
      psd.ageMax = random(180);
      psd.angVel.set(0, 0, random(-1,1));
      psd.die = true;
      psd.scalar = random(0.25, 0.75);
      pm.addDebris(psd);
    }
    // Sparks
    for(int j = 0;  j < 64;  j++)
    {
      float rSpd = 4;
      PVector rDir = new PVector(1,0);
      rDir.rotate(random(TWO_PI));
      rDir.mult(pow(random(1.0), 2) * rSpd);
      PImage pimg = image_spark;
      ParticleSpriteDecay psd = new ParticleSpriteDecay(pos.x, pos.y, pos.z,
        rDir.x, rDir.y, random(10),
        pimg, color(255,16,192, 255), color(255,255,16) );
      psd.ageMax = random(60);
      psd.trail = true;
      psd.die = true;
      psd.scalar = random(0.5, 1.0);
      pm.addDebris(psd);
    }
    // Debris chunks
    for(int j = 0;  j < 64;  j++)
    {
      float rSpd = 1;
      PVector rDir = new PVector(1,0);
      rDir.rotate(random(TWO_PI));
      rDir.mult(pow(random(1.0), 2) * rSpd);
      PImage pimg = image_chunk;
      ParticleSpriteDecay psd = new ParticleSpriteDecay(pos.x, pos.y, pos.z,
        rDir.x, rDir.y, random(10),
        pimg, color(255,16,192, 255), color(255,255,16) );
      psd.ageMax = random(512);
      psd.angVel.set(0, 0, random(-0.1,0.1));
      psd.die = true;
      psd.scalar = random(0.5);
      pm.addDebris(psd);
    }
  }
  // doImpact
  
}
// Story







class StoryEvent
// Event to trigger at a certain time
{
  float triggerTime;
  int commandCode;
  float checkTime, lastCheckTime;
  boolean triggered;
  
  StoryEvent(float triggerTime, int commandCode)
  {
    this.triggerTime = triggerTime;
    this.commandCode = commandCode;
    checkTime = 0;
    lastCheckTime = -1;
    triggered = false;
  }
  
  
  boolean isTriggered(float inputTime)
  // Check whether the time has passed over the trigger
  {
    // Update time values
    lastCheckTime = checkTime;
    checkTime = inputTime;
    
    // Check for crossover
    //   by using multiplication method: only one positive and one negative produce negatives
    if( (triggerTime - lastCheckTime) * (triggerTime - checkTime) <= 0 )
    {
      triggered = true;
      return(true);
    }
    else  return(false);
  }
  // isTriggered
}
// StoryEvent
