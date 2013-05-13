/*

Combination testbed

Implements:

Normal mapping (very slow)
  - corrected angular illumination from directional lights

Lights (in point, directional, and spot varieties, with colour)

Particles
  - simple physical particles
  - sprite particles
  - sprite particles that decay
  - sprite particles with normal maps that react to linked lights

Collision maps (able to receive ID stencils from sprite particles)

Particle Manager

Particle Emitters

Unified Lighting Model within Particle Manager

Story Setup (hard-coded story events on a timer)

*/


// Imports

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;




// Graphics assets
PImage image_null;
PImage image_starscape;

// Particles
ParticleManager particleManager;

// Story
Story story;

// Collision systems
PGraphics collMap;

// Sound systems

Minim minim;
AudioPlayer audioPlayer;

// Acceleration switch
boolean FAST = true;
// This just disables all consideration of normal maps

// Rendering systems
boolean RECORD = false;




void setup()
{
  // Initiate graphics
  
  size(1920, 1080, P2D);
  
  
  // Initiate seed to ensure repeatibility
  
  randomSeed(0);
  
  
  // Collision systems
  
  collMap = createGraphics(width, height, P2D);
  
  
  // Load data
  
  image_null = loadImage("null.png");
  image_starscape = loadImage("starscape.png");
  
  
  // Setup particle management
  
  particleManager = new ParticleManager();
  
  
  // Setup story management
  
  story = new Story(particleManager);
  story.timeMode = FAST  ?  0  :  1;
  //story.timeMode = 0;  // Realtime
  //story.timeMode = 1;  // Render every frame
  
  
  // Setup sound system
  minim = new Minim(this);
  
  // Initialise sounds
  // Load music
  audioPlayer = minim.loadFile("Mozart - Requiem Mass in D Minor - 01-01 - I- Introitus Adagio.mp3");
  // Play music forever
  audioPlayer.play();
  audioPlayer.loop();
  
}


void draw()
{
  // Manage story
  story.run();
  
  
  // Set backdrop
  image(image_starscape, 0, 0, width, height);
  
  
  // Manage particles
  particleManager.run(story.tick);
  
  
  // Fade in / fade out
  float fadeIn = 255 - (frameCount / 4.0);
  float fadeOut = 255 - ( (10845 * 4.0) - (frameCount / 4.0) );
  float fade = max(fadeIn, fadeOut);
  if(0 < fade)
  {
    pushStyle();
    fill(0, fade);
    noStroke();
    rect(0,0, width,height);
    popStyle();
  }
  
  
  // Manage recording
  if(RECORD)
  {
    save("renders/render"+nf(frameCount, 6)+".png");
  }
  
  
  /*
  // Draw the collision map as an overlay
  tint(255, 64);
  image(collMap,0,0);
  */
  
  
  // Diagnostic
  if(frameCount % 60 == 0)
  {
    //println("Framerate " + frameRate);
    //println( "  Particle count: " + particleManager.pMasterList.size() );
    //println( "  Shot count:     " + particleManager.pShotList.size() );
  }
}



void keyReleased()
{
  if(key == ' ')
  {
    // SPACE
    // Pause simulation
    story.pause = !story.pause;
    if(story.pause)
    {
      audioPlayer.pause();
      noLoop();
    }
    else
    {
      audioPlayer.play();
      loop();
    }
  }
  
  if( (key == 'q')  ||  (key == 'Q') )
  {
    // Q
    // Toggle quality mode
    // To prevent horrible simulation glitches, this doesn't reenable realtime
    FAST = !FAST;
    if(!FAST)  story.timeMode = 1;
  }
  
  if( (key == 'f')  ||  (key == 'F') )
  {
    // F
    // Toggle fast mode
    // This is like quality mode, only without the quality
    if(story.timeMode == 0)  story.timeMode = 1;
    else                     story.timeMode = 0;
  }
  
  if( (key == 'r')  ||  (key == 'R') )
  {
    // R
    // Toggle record mode
    RECORD = !RECORD;
    // Set unitary frames to ignore the massive time cost of saving files
    story.timeMode = 1;
  }
  
  if( (key == 's')  ||  (key == 'S') )
  {
    // S
    // Screenshot
    save("ScreenGrab"+year()+""+month()+""+day()+""+hour()+""+minute()+""+second()+".png");
  }
  
  if( (key == 'm')  ||  (key == 'M') )
  {
    // M
    // Mute music
    // It won't come back
    audioPlayer.pause();
  }
  
}



void stop()
{
  // Always close minim
  audioPlayer.close();
  minim.stop();
  
  // Super
  super.stop();
}




void imagePG(PGraphics pg, float x, float y, PGraphics canvas)
// Helper for overcoming inverted graphics from image(pg);
// canvas parameter must be primed for draw
{
  canvas.pushMatrix();
  canvas.translate(x, y + pg.height);
  canvas.scale(1, -1);
  canvas.image(pg, 0, 0);
  canvas.popMatrix();
}
// imagePG

void imagePG(PGraphics pg, float x, float y)
// Generic viewport version
{
  imagePG(pg, x, y, g);
}
// imagePG
