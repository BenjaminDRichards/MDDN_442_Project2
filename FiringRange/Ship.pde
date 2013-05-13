import java.util.*;

class Ship extends ParticleSpriteNormalMap
// Something that flies through space and is illuminated and collides with shots
// It carries a series of emitters with it
{
  // Emitter register
  ArrayList emitters;
  ArrayList emitterOffsets;
  
  Ship(float px, float py, float pz, float vx, float vy, float vz, PImage img, PImage normalMap)
  {
    super(px, py, pz,  vx, vy, vz,  img, normalMap);
    
    // Setup emitter list
    emitters = new ArrayList();
    emitterOffsets = new ArrayList();
  }
  
  
  void run(float tick)
  // Extend template to handle slaved emitters
  {
    super.run(tick);
    
    // Slave emitters
    Iterator i = emitters.iterator();
    Iterator io = emitterOffsets.iterator();
    while( i.hasNext() )
    {
      // Get next information
      Emitter e = (Emitter) i.next();
      PVector offset = ((PVector)io.next()).get();
      
      // Update emitter position
      conformEmitter(e, offset);
      
      // Removal
      // If the emitter needs to be ended, do it here
      
      // Validity check
      if(frameCount % 10 == 0)
      // Cull emitters that are attached to empty space
      if( (4 < e.pos.x)  &&  (e.pos.x < width - 5)  &&  (4 < e.pos.y)  &&  (e.pos.y < height - 5) )
      {
        // That is, we are on the screen and collision maps are available
        color probe = collMap.get( floor(e.pos.x), floor(e.pos.y) );    // Accessing system-wide collMap
        if(alpha(probe) < 127)
        {
          // The probe is on translucent collision and should be culled
          e.pleaseRemove = true;
        }
      }
    }
  }
  // run
  
  
  void conformEmitter(Emitter e, PVector offset)
  // Place the emitter according to its offset information relative to ship
  {
    // Compute transformed offset
    PVector tOffset = offset.get();
    tOffset.rotate(ang.z);
    tOffset.mult(scalar);
    
    // Set emitter position
    e.setPos(new PVector(pos.x + tOffset.x,  pos.y + tOffset.y,  pos.z + tOffset.z) );
  }
  // conformEmitter
  
  
  void addEmitter(Emitter e, PVector offset)
  // Register an emitter to this ship
  // Use only this method to avoid accidental desynch between emitters and offsets
  {
    emitters.add(e);
    emitterOffsets.add(offset);
    conformEmitter(e, offset);
  }
  // addEmitter
  
  
  void addEmitterWorld(Emitter e, PVector worldPos)
  // Register an emitter to this ship using world space coordinates
  {
    // Compute object space coords
    PVector offset = PVector.sub(worldPos, pos);
    offset.mult(1 / scalar);
    PVector offset2D = new PVector(offset.x, offset.y);
    offset2D.rotate(-ang.z);
    offset.set(offset2D.x, offset2D.y, offset.z);    // Note that the "z" is preserved
    
    // Add emitter
    addEmitter(e, offset);
  }
  // addEmitterWorld
  
}
// Ship
