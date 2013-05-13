class Particle
// Contains a particle that moves about according to physics
{
  // Physics data
  PVector pos, vel, ang, angVel, posLast;
  boolean angle2D;
  float inertia, inertiaAng;
  boolean trail;  // Does the orientation conform to the velocity?
  // Lifespan data
  float age, ageMax;
  boolean die, pleaseRemove;
  // Rendering data
  PGraphics canvas;
  
  
  Particle(float px, float py, float pz, float vx, float vy, float vz)
  {
    // Physics data from args
    pos = new PVector(px, py, pz);
    vel = new PVector(vx, vy, vz);
    posLast = PVector.sub(pos, vel);
    inertia = 1.0;
    inertiaAng = 1.0;
    trail = false;
    
    // Default angular parameters
    ang = new PVector(0,0,0);
    angVel = new PVector(0,0,0);
    angle2D = true;
    
    // Default lifespan parameters
    age = 0;
    ageMax = 1;
    die = false;
    pleaseRemove = false;
    
    // Graphics setup
    // By default, uses the default PGraphics object
    canvas = g;
  }
  
  
  void run(float tick)
  // Advance the particle by a proportion of expected frame length
  {
    // Position physics
    posLast = pos.get();
    pos.add(PVector.mult(vel, tick));
    vel.mult(inertia);
    
    if(trail)
    {
      // Trail physics
      // Compute angle according to velocity
      // Because angle is stored as gimbals, not a directional vector,
      //   this must be computed.
      if(0 < vel.mag())
      {
        // Update angle only if the particle is moving
        float angZ = ( new PVector(-vel.y, vel.x) ).heading();  // I know this is right
        float angY = ( new PVector(vel.x, vel.z) ).heading();  // Untested
        float angX = ( new PVector(vel.y, vel.z) ).heading();  // Untested
        ang.set(angX, angY, angZ);
      }
    }
    else
    {
      // Rotation physics
      ang.add(PVector.mult(angVel, tick));
      angVel.mult(inertiaAng);
    }
    
    // Lifespan
    age += tick;
    if(die  &&  ageMax <= age)  pleaseRemove = true;
  }
  // run
  
  
  void render()
  // Draw particle
  // This will fail on a canvas that's not ready to render
  {
    canvas.pushMatrix();
    canvas.translate(pos.x, pos.y);
    if(angle2D)
    {
      // No 3D canvas, rotate using the Z axis
      canvas.rotate(ang.z);
    }
    else
    {
      canvas.rotateX(ang.x);
      canvas.rotateY(ang.y);
      canvas.rotateZ(ang.z);
    }
    this.draw();
    canvas.popMatrix();
  }
  // render
  
  
  void draw()
  // What actually reaches the canvas on drawing
  {
    canvas.point(0,0);
  }
  // draw
}
// Particle


class ParticleSprite extends Particle
// Particle that has an associated sprite
// I can run up to about 4096 of these with 32x32 sprites at 60fps
{
  // Graphics data
  PImage img;
  // Style data
  color spriteTint;
  // Time-saving data
  PVector drawOffset;
  // Identification data
  color id;
  PImage collStencil;
  // Draw data
  float scalar;
  
  ParticleSprite(float px, float py, float pz, float vx, float vy, float vz, PImage img)
  {
    super(px, py, pz, vx, vy, vz);
    
    // Get sprite graphics
    this.img = img;
    
    // Style defaults
    spriteTint = color(255,255,255, 255);
    
    // Create sprite offset
    drawOffset = new PVector(-img.width/2.0, -img.height/2.0);
    
    // Setup identification
    id = #000000;
    
    // Setup default draw data
    scalar = 1.0;
  }
  
  
  void draw()
  // Override super
  {
    // Scale sprite
    canvas.scale(scalar);
    // Center sprite
    canvas.translate(drawOffset.x, drawOffset.y);
    // Render sprite
    canvas.pushStyle();
    canvas.tint(spriteTint);
    canvas.image(img,  0, 0,  img.width, img.height);
    canvas.popStyle();
  }
  // draw
  
  
  void loadStencil(PImage collStencil)
  // Load in a collision stencil
  // This doesn't happen by default to save memory
  {
    this.collStencil = collStencil;
  }
  // loadStencil
  
  
  
  void renderCollisionData(PGraphics collMap)
  // Put a color-coded onto the specified collision map
  {
    if(collStencil != null)
    {
      collMap.pushMatrix();
      collMap.translate(pos.x, pos.y);
      if(angle2D)
      {
        // No 3D canvas, rotate using the Z axis
        collMap.rotate(ang.z);
      }
      else
      {
        collMap.rotateX(ang.x);
        collMap.rotateY(ang.y);
        collMap.rotateZ(ang.z);
      }
      // Scale sprite
      collMap.scale(scalar);
      // Center sprite
      collMap.translate(drawOffset.x, drawOffset.y);
      // Render sprite
      collMap.pushStyle();
      collMap.tint(id);
      collMap.image(collStencil,  0, 0,  collStencil.width, collStencil.height);
      collMap.popStyle();
      // Finish
      collMap.popMatrix();
    }
  }
  // renderCollisionData
}
// ParticleSprite


class ParticleSpriteDecay extends ParticleSprite
{
  color col1, col2;
  
  ParticleSpriteDecay(float px, float py, float pz, float vx, float vy, float vz, PImage img, color col1, color col2)
  {
    super(px, py, pz, vx, vy, vz, img);
    
    this.col1 = col1;
    this.col2 = col2;
  }
  
  void draw()
  // Override super
  {
    // Determine normalised age
    float ageNorm = age / ageMax;
    // Style draw
    float r = lerp(red(col1), red(col2), ageNorm);
    float g = lerp(green(col1), green(col2), ageNorm);
    float b = lerp(blue(col1), blue(col2), ageNorm);
    float aleph = constrain( lerp(alpha(col1), 0, ageNorm),  0, 255);
    spriteTint = color(r, g, b, aleph);
    // Draw
    super.draw();
  }
  // draw
  
}


class ParticleSpriteNormalMap extends ParticleSprite
{
  NormalMap normalMap;
  PGraphics drawBuffer;
  
  ParticleSpriteNormalMap(float px, float py, float pz, float vx, float vy, float vz, PImage img, PImage normalMap)
  {
    super(px, py, pz, vx, vy, vz, img);
    
    // Setup normal mapping
    this.normalMap = new NormalMap(normalMap);
    
    // Setup special blending buffer
    drawBuffer = createGraphics(img.width, img.height, P2D);
    // Prefill draw buffer for fast graphics mode
    drawBuffer.beginDraw();
    drawBuffer.clear();
    drawBuffer.image(img,0,0);
    drawBuffer.endDraw();
  }
  
  
  void run(float tick)
  // Extend run functionality
  // This is heavily enhanced to provide normal-based lighting
  {
    super.run(tick);
    
    // Advanced shading
    if( !FAST  &&  (0 < tick) )
    {
      // That is, slow rendering and time is passing
      
      // Compute normal map for new position
      PVector rotOffset = drawOffset.get();
      rotOffset.rotate(ang.z);
      rotOffset.mult(scalar);
      normalMap.pos.set(pos.x + rotOffset.x, pos.y + rotOffset.y, pos.z);
      normalMap.ang = ang.z;
      normalMap.scalar = scalar * normalMap.scalar_to_master;
      
      //
      // Disable this for fast diagnostic view
      //
      normalMap.render();
      
      // Compute new composite graphics
      // This makes multiple renders take zero extra time over normal sprites
      
      // Update draw buffer
      drawBuffer.beginDraw();
      drawBuffer.clear();
      drawBuffer.image(img,0,0);
      // Apply lighting
      // Doing this inside the buffer is more reliable than outside
      drawBuffer.blend(normalMap.lightBuffer, 0, 0, normalMap.lightBuffer.width, normalMap.lightBuffer.height,
        0, 0, drawBuffer.width, drawBuffer.height,  HARD_LIGHT);
      // Complete
      drawBuffer.endDraw();
    }
  }
  // run
  
  
  void draw()
  // Render sprite with normal map
  {
    // Copied from incompatible template:
    // Scale sprite
    canvas.scale(scalar);
    // Center sprite
    canvas.translate(drawOffset.x, drawOffset.y);
    
    // Novel code:
    
    // Put to screen
    //this.imagePG(drawBuffer, 0,0, canvas);
    canvas.image(drawBuffer, 0,0);
  }
  // draw
}
// ParticleSpriteNormalMap
