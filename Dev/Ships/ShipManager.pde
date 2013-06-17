class ShipManager
// Keep all the ships in one place to provide for easy navigation
{
  ArrayList ships;
  
  public static final int MODEL_PREY_A = 1;
  
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
  
  
  public Ship makeShip(PVector pos, int model)
  {
    Ship ship = new Ship(pos, pos);
    ships.add(ship);
    
    // Configure ship model
    switch(model)
    {
      case MODEL_PREY_A:
        ship.configureAsPreyA();
        break;
      default:
        break;
    }
    
    return( ship );
  }
  // makeShip
}
// ShipManager
