import java.util.*;

class ParticleManager
// Manages the particle systems of the game
{
  // Particle lists
  ArrayList pMasterList;    // Sum of all lists. Particles that behave and render, depth-sorted
  ArrayList pShipList;      // Particles that are ships, and have collision data and lit normal maps
  ArrayList pEmitterList;   // Particles that are emitters, with attached lights and particle generation
  ArrayList pShotList;      // Particles that are shots, which create light and collide with ships, and die out-of-bounds
  ArrayList pDebrisList;    // Particles that are debris, which ages and fades from view or when out-of-bounds
  
  // Master lighting array
  ArrayList lightMasterList;
  
  // Collision space
  PGraphics cMap;
  
  // Area bounds
  PVector lowBound, highBound;
  
  
  ParticleManager()
  {
    pMasterList = new ArrayList();
    pShipList = new ArrayList();
    pEmitterList = new ArrayList();
    pShotList = new ArrayList();
    pDebrisList = new ArrayList();
    
    // Setup lighting
    lightMasterList = new ArrayList();
    
    // Setup collision space
    cMap = collMap;
    
    // Setup default bounds
    lowBound = new PVector(-width, -height);
    highBound = new PVector(2 * width, 2 * height);
  }
  
  
  void run(float tick)
  // Call once per frame
  {
    // Rebuild master list from sublists
    pMasterList.clear();
    pMasterList.addAll(pShipList);
    pMasterList.addAll(pEmitterList);
    pMasterList.addAll(pShotList);
    pMasterList.addAll(pDebrisList);
    
    // Sort master list for depth
    pMasterList = quickSort(pMasterList);
    
    // Setup iteration
    Iterator i;
    
    
    
    // Run physics and culling on master list
    // This will also build normal maps for normal-mapped sprites
    i = pMasterList.iterator();
    while( i.hasNext() )
    {
      Particle p = (Particle) i.next();
      p.run(tick);
    }
    
    
    
    // Run ships
    i = pShipList.iterator();
    cMap.beginDraw();
    cMap.clear();
    while( i.hasNext() )
    {
      Ship p = (Ship) i.next();
      // Run collision rendering on ship list
      p.renderCollisionData(cMap);
      
      // Enforce lighting
      p.normalMap.lightList = this.lightMasterList;
      
      // Check for out-of-bounds
      if(
        (p.pos.x < lowBound.x)  ||
        (highBound.x < p.pos.x)  ||
        (p.pos.y < lowBound.y)  ||
        (highBound.y < p.pos.y)
        )
      {
        // Out of bounds, remove
        p.pleaseRemove = true;
      }
      
      // Manage death
      if(p.pleaseRemove)
      {
        pShipList.remove(p);
        
        // Remove emitters
        Iterator j = p.emitters.iterator();
        while( j.hasNext() )
        {
          // Get emitter
          Emitter e = (Emitter) j.next();
          
          // Deregister emitter
          removeEmitter(e);
        }
      }
    }
    collMap.endDraw();
    
    
    
    // Run emitters list
    // Also manage emitter death
    i = pEmitterList.iterator();
    while( i.hasNext() )
    {
      Emitter e = (Emitter) i.next();
      if(e.pleaseRemove)
      {
        i.remove();
        // Remove associated light
        Light lg = e.light;
        lightMasterList.remove(lg);
      }
    }
    
    
    
    // Run collision checks on shot list
    // Also manage shot death due to collision or out-of-bounds
    // Also manage lights associated with these shots
    i = pShotList.iterator();
    while( i.hasNext() )
    {
      Shot p = (Shot) i.next();
      
      // Check for cull requests
      // We do this here so the particle still has an effect later in the frame
      //  and avoiding blank frames
      if(p.pleaseRemove)
      {
        i.remove();
        // Remove associated light
        Light lg = p.light;
        lightMasterList.remove(lg);
      }
      
      // Collision check
      if(p.pos.z * p.posLast.z <= 0)
      {
        // That is, it has passed through or sat upon the collision plane at z = 0
        // We know this because z*z < 0 only if one is positive and one is negative
        
        // Collision probe
        int x = constrain(int(p.pos.x),  0, cMap.width - 1);
        int y = constrain(int(p.pos.y),  0, cMap.height - 1);
        color probe = cMap.get(x, y);
        
        // Probe check
        if(250 <= alpha(probe))
        {
          // Solid collision
          // We're not picking 255 because sometimes colour gets distorted on rescale.
          //println("Collided with object id " + probe);
          
          // Remove particle from shot list
          p.pleaseRemove = true;
          
          // Create poof
          p.doImpact(this);
          
          // Add impact emitter
          Iterator iShip = pShipList.iterator();
          while( iShip.hasNext() )
          {
            Ship ship = (Ship) iShip.next();
            if(probe == ship.id)
            {
              // This is the ship we're looking for
              
              // Create impact emitter
              Emitter_Impact ei = new Emitter_Impact(0,0,0,  0,0,0,  image_null, this);
              ship.addEmitterWorld( ei, new PVector(p.pos.x, p.pos.y, ship.pos.z + 1) );
              
              // Register impact emitter
              addEmitter(ei);
              //println("Registered emitter to id " + ship.id + " at position " + ei.pos);
              break;
            }
            if( !iShip.hasNext() )
            {
              // Failed to identify ship
              println("Failed to identify ship");
            }
          }
        }
      }
      
      // Check for out-of-bounds
      if(
        (p.pos.x < lowBound.x)  ||
        (highBound.x < p.pos.x)  ||
        (p.pos.y < lowBound.y)  ||
        (highBound.y < p.pos.y)
        )
      {
        // Out of bounds, remove
        p.pleaseRemove = true;
      }
      
      // Removal
      
      // Removal takes place on the next frame, before simulation
    }
    
    
    
    // Run out-of-bounds checks and culls on debris list
    i = pDebrisList.iterator();
    while( i.hasNext() )
    {
      Particle p = (Particle) i.next();
      // Check for out-of-bounds
      if(
        (p.pos.x < lowBound.x)  ||
        (highBound.x < p.pos.x)  ||
        (p.pos.y < lowBound.y)  ||
        (highBound.y < p.pos.y)
        )
      {
        // Out of bounds, remove
        p.pleaseRemove = true;
      }
      // Check for cull requests
      if(p.pleaseRemove)
      {
        i.remove();
      }
    }
    
    
    
    // Run rendering on master list
    i = pMasterList.iterator();
    while( i.hasNext() )
    {
      Particle p = (Particle) i.next();
      p.render();
    }
  }
  // run
  
  
  ArrayList quickSort(ArrayList list)
  // Quicksort list via recursion
  // This version sorts Particles based on particle.pos.z, from low to high.
  {
    if(list.size() < 2)
    {
      // 0 or 1 elements do not need sorting
      return(list);
    }
    
    // Deal with 2+ element lists via recursion
    
    // Select pivot
    int pivotPos = int(list.size() / 2);
    Particle pivot = (Particle) list.get(pivotPos);
    list.remove(pivotPos);
    // Create high and low lists
    ArrayList low = new ArrayList();
    ArrayList high = new ArrayList();
    // Assign values to high and low lists
    while(0 < list.size())
    {
      Particle p = (Particle) list.get(0);
      list.remove(0);
      if(p.pos.z < pivot.pos.z)  low.add(p);
      else                       high.add(p);
    }
    // Quicksort high and low lists
    low = quickSort(low);
    high = quickSort(high);
    // Concatenate low, pivot, and high
    list.addAll(low);
    list.add(pivot);
    list.addAll(high);
    // Return
    return(list);
  }
  // quickSortMasterList
  
  
  void addShot(Shot shot)
  // Adds a shot and associated light to manager
  {
    pShotList.add(shot);
    lightMasterList.add(shot.light);
  }
  // addShot
  
  
  void addShip(Ship ship)
  // Adds a ship and updates its lighting list
  {
    pShipList.add(ship);
    ship.normalMap.lightList = this.lightMasterList;
  }
  
  
  void addDebris(Particle p)
  // Adds a miscellaneous particle to manager
  {
    pDebrisList.add(p);
  }
  // addDebris
  
  
  void addEmitter(Emitter e)
  // Adds an emitter and associated light to manager
  {
    pEmitterList.add(e);
    lightMasterList.add(e.light);
  }
  // addEmitter
  
  
  void addLight(Light lg)
  // Adds a light to unified lighting manager
  {
    lightMasterList.add(lg);
  }
  // addLight
  
  
  void removeShot(Shot s)
  // Removes a shot from the scene
  // and updates associated lighting
  {
    pShotList.remove(s);
    lightMasterList.remove(s.light);
  }
  
  
  void removeEmitter(Emitter e)
  // Removes an emitter from the scene
  // and updates associated lighting
  {
    pEmitterList.remove(e);
    lightMasterList.remove(e.light);
  }
  // removeEmitter
  
  
  void removeShip(Ship s)
  // Removes a ship from the scene
  // and updates associated emitters
  {
    pShipList.remove(s);
    
    // Remove emitters
    Iterator i = s.emitters.iterator();
    while( i.hasNext() )
    {
      // Get emitter
      Emitter e = (Emitter) i.next();
      
      // Deregister emitter
      removeEmitter(e);
    }
  }
  // removeShip
  
}
// ParticleManager
