/*
  Ship navigation and animation program
  
  This code generates and controls some ships that fly around.
  They use DAG nodes for sub-animation and positioning.
*/


import java.util.*;


Story story;

PGraphics testShipSprite;
ShipManager testShipManager;


void setup()
{
  size(1920, 1080, P2D);
  
  // Setup story
  story = new Story();
  
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
  testShipManager = new ShipManager();
  for(int i = 0;  i < 48;  i++)
  {
    PVector pos = new PVector(random(-50,50), random(100), 0);
    PVector targetPos = pos.get();
    targetPos.add( PVector.random3D() );
    testShipManager.makeShip(pos, targetPos, ShipManager.MODEL_PREY_A, 0);
  }
  /*
  {
    // Test missile turret A
    PVector pos = new PVector(50, 50, 0);
    PVector targetPos = pos.get();
    targetPos.add( new PVector(-1, 1, 0) );
    Ship turret = testShipManager.makeShip(pos, targetPos, ShipManager.MODEL_TURRET_MISSILE_A, 1);
  }
  {
    // Test bullet turret A
    PVector pos = new PVector(25, 50, 0);
    PVector targetPos = pos.get();
    targetPos.add( new PVector(0, 1, 0) );
    Ship turret = testShipManager.makeShip(pos, targetPos, ShipManager.MODEL_TURRET_BULLET_A, 1);
  }
  */
  {
    // Test gunboat
    PVector pos = new PVector(0, 50, 0);
    PVector targetPos = pos.get();
    targetPos.add( new PVector(0, 1, 0) );
    Ship gunboat = testShipManager.makeShip(pos, targetPos, ShipManager.MODEL_GUNBOAT, 1);
  }
}
// setup


void draw()
{
  noStroke();
  
  // Start percentile coordinates
  pushMatrix();
  scale(height * 0.01, height * 0.01);          // Percentile coordinate system
  translate( 50.0 * width / height, 0 );       // Go to middle of screen
  
  
  // Manage story
  story.run();
  
  // Test ship code
  testShipManager.run(story.tick);
  testShipManager.render();
  /*
  // DAG visualiser
  ArrayList dags = testShip.getRoot().getAllChildren();
  dags.add( testShip.getRoot() );
  dags.addAll( testShip.getFragments() );
  debugDags(dags);
  */
  
  // End percentile coordinates
  popMatrix();
  
  
  // Diagnostics
  if(frameCount % 60 == 0)  println("FPS " + frameRate);
}
// draw


void mouseReleased()
{
  // Convert mouse coordinates to screen space
  float mx = screenMouseX();
  float my = screenMouseY();
  
  if(mouseButton == LEFT)
  {
    PVector pos = new PVector(mx, my, 0);
    PVector targetPos = pos.get();
    targetPos.add( PVector.random3D() );
    Ship s = testShipManager.makeShip( pos, targetPos, ShipManager.MODEL_MISSILE_A, 1);
    s.team = 1;
  }
  
  if(mouseButton == RIGHT)
  {
    PVector pos = new PVector(mx, my, 0);
    PVector targetPos = pos.get();
    targetPos.add( PVector.random3D() );
    Ship s = testShipManager.makeShip( pos, targetPos, ShipManager.MODEL_BULLET_A, 1);
    s.team = 1;
  }
}
// mouseReleased


void keyPressed()
{
  // No keys yet
  
  if(key == ' ')
  {
    if( 0 < testShipManager.ships.size() )
    {
      Ship s = (Ship) testShipManager.ships.get(0);
      s.startExploding();
    }
  }
}
// keyPressed



float screenMouseX()
// Convert mouseX to screen space
{
  return( (mouseX - width * 0.5) * 100.0 / height );
}
// screenMouseX

float screenMouseY()
// Convert mouseY to screen space
{
  return( mouseY * 100.0 / height );
}
// screenMouseX



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
