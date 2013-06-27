import java.util.*;

class ShipManager
// Keep all the ships in one place to provide for easy navigation
{
  ArrayList ships, shipsNew;
  
  public static final int MODEL_PREY_A = 1;
  public static final int MODEL_GUNBOAT = 2;
  public static final int MODEL_TURRET_MISSILE_A = 10;
  public static final int MODEL_TURRET_BULLET_A = 11;
  public static final int MODEL_MISSILE_A = 20;
  public static final int MODEL_BULLET_A = 21;
  
  ShipManager()
  {
    ships = new ArrayList();
    shipsNew = new ArrayList();
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
    
    // Append additions list
    ships.addAll(shipsNew);
    shipsNew.clear();
  }
  // run
  
  
  public void render(RenderManager renderManager)
  {
    Iterator i = ships.iterator();
    while( i.hasNext() )
    {
      Ship s = (Ship) i.next();
      s.render(renderManager);
    }
  }
  // render
  
  
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
  
  
  public Ship makeShip(PVector pos, PVector targetPos, int model, int team)
  {
    Ship ship = new Ship(pos, targetPos, Ship.NAV_MODE_AVOID, this, team);
    shipsNew.add(ship);
    
    // Configure ship model
    switch(model)
    {
      case MODEL_PREY_A:
        ship.configureAsPreyA();
        break;
      case MODEL_GUNBOAT:
        ship.configureAsGunboat();
        break;
      case MODEL_TURRET_MISSILE_A:
        ship.configureAsTurretMissileA();
        break;
      case MODEL_TURRET_BULLET_A:
        ship.configureAsTurretBulletA();
        break;
      case MODEL_MISSILE_A:
        ship.configureAsMissileA();
        break;
      case MODEL_BULLET_A:
        ship.configureAsBulletA();
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
      if(s.team != friendlyTeam  &&  !s.exploding  &&  s.targetable)
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
  
  
  public ArrayList getEnemiesOf(int friendlyTeam)
  {
    ArrayList enemies = new ArrayList();
    Iterator i = ships.iterator();
    while( i.hasNext() )
    {
      Ship s = (Ship) i.next();
      if(s.team != friendlyTeam  &&  !s.exploding  &&  s.targetable)
        enemies.add(s);
    }
    
    return( enemies );
  }
  // getEnemiesOf
}
// ShipManager
