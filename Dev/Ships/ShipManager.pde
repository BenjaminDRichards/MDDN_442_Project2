import java.util.*;

class ShipManager
// Keep all the ships in one place to provide for easy navigation
{
  ArrayList ships;
  
  public static final int MODEL_PREY_A = 1;
  public static final int MODEL_MISSILE_A = 10;
  
  ShipManager()
  {
    ships = new ArrayList();
  }
  
  
  public void run(float tick)
  {
    Iterator i = ships.iterator();
    while( i.hasNext() )
    {
      Ship s = (Ship) i.next();
      s.run(tick);
      if(s.pleaseRemove)  i.remove();
    }
  }
  // run
  
  
  public void render(PGraphics pg)
  {
    Iterator i = ships.iterator();
    while( i.hasNext() )
    {
      Ship s = (Ship) i.next();
      s.render(pg);
    }
    
    // Render weapon effects over all the ships
  }
  public void render()  {  render(g);  }
  // render
  
  
  public Ship makeShip(PVector pos, PVector targetPos, int model)
  {
    Ship ship = new Ship(pos, targetPos, Ship.NAV_MODE_AVOID, this);
    ships.add(ship);
    /*
    Ship ship = new Ship(pos, targetPos, Ship.NAV_MODE_HOMING, this);
    model = MODEL_MISSILE_A;
    ship.team = floor( random(4) );
    ships.add(ship);
    */
    
    // Configure ship model
    switch(model)
    {
      case MODEL_PREY_A:
        ship.configureAsPreyA();
        break;
      case MODEL_MISSILE_A:
        ship.configureAsMissileA();
        break;
      default:
        break;
    }
    
    return( ship );
  }
  // makeShip
  
  
  public Ship getNearestShipTo(PVector pos)
  {
    if(ships.size() == 0)  return( null );
    
    Ship sCandidate = (Ship) ships.get(0);
    float dCandidate = sCandidate.getRoot().getWorldPosition().dist(pos);
    Iterator i = ships.iterator();
    while( i.hasNext() )
    {
      Ship s = (Ship) i.next();
      float d = s.getRoot().getWorldPosition().dist(pos);
      if(d < dCandidate)
      {
        sCandidate = s;
        dCandidate = d;
      }
    }
    return( sCandidate );
  }
  // getNearestShipTo
  
  
  public Ship getNearestEnemyTo(PVector pos, int friendlyTeam)
  {
    if(ships.size() == 0)  return( null );
    
    Ship sCandidate = null;
    float dCandidate = -1;
    Iterator i = ships.iterator();
    while( i.hasNext() )
    {
      Ship s = (Ship) i.next();
      if(s.team != friendlyTeam)
      {
        float d = s.getRoot().getWorldPosition().dist(pos);
        if( (d < dCandidate)  ||  (sCandidate == null) )
        {
          sCandidate = s;
          dCandidate = d;
      }
      }
    }
    return( sCandidate );
  }
  // getNearestEnemyTo
}
// ShipManager
