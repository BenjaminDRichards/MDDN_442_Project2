class Hud
{
  PGraphics output;
  Ship ship;
  
  Hud(PGraphics template)
  {
    output = createGraphics(template.width, template.height, P2D);
    
    ship = playerShip;
  }
  
  
  void drawHUD()
  {
    float cloakDim = 0.5 - 0.35 * ship.cloakActivation;
    float textScale = output.height / 2160.0;
    float cornerX = 0;  float cornerY = 0;  // Reused assets
    
    // Draw activity meters
    output.beginDraw();
    output.noStroke();
    output.clear();
    output.pushMatrix();
    output.pushStyle();
    
    output.noStroke();
    output.fill(GUI_COLOR, 255 * cloakDim);
    output.tint(GUI_COLOR, 255 * cloakDim);
    //output.textSize(18 * output.height / 1080.0);
    output.translate(output.width * 0.5, output.height * 0.9);
    
    // Helm activation gauge
    if(0 < ship.excitement)
    {
      output.rect(output.width * 0.01, 0,  output.width * 0.4 * ship.excitement, output.height * 0.001);
      // Label above gauge: "regional supremacy assertion ONLINE"
      if(ship.cloakActivation == 0)
      {
        cornerX = output.width * 0.41 - ( hud_element_online.width * textScale );
        cornerY = output.height * -0.01 - (hud_element_online.height * textScale );
        output.image(hud_element_online,
          cornerX, cornerY,
          hud_element_online.width * textScale, hud_element_online.height * textScale);
      }
    }
    // Label below gauge: "HELM GUIDANCE"
    cornerX = output.width * 0.01;
    cornerY = output.height * 0.01;
    output.image(hud_element_helm,
      cornerX, cornerY,
      hud_element_helm.width * textScale, hud_element_helm.height * textScale);
    
    // Super-gauge: FPS
    output.pushMatrix();
    output.translate(output.width * 0.01, output.height * -0.013);
    for(int i = 0;  i <= frameRate;  i += 8)
    {
      output.rect(0, 0, output.width * 0.01, output.height * -0.002);
      output.translate(output.width * 0.012, 0.0);
    }
    output.popMatrix();
    
    // Input icon
    output.pushStyle();
    output.stroke(GUI_COLOR, 128 * cloakDim);
    output.strokeWeight(output.height * 0.002);
    output.noFill();
    if(camActive)
    {
      output.rect(output.width * 0.41, output.height * -0.04,   output.height * -0.02, output.height * -0.02);
      output.ellipse(output.width * 0.41 - output.height * 0.01, output.height * -0.05,
                     output.height * -0.01,                      output.height * -0.01);
    }
    else
    {
      output.ellipse(output.width * 0.41 - output.height * 0.01, output.height * -0.05,
                     output.height * 0.015,                       output.height * 0.02);
      output.line(output.width * 0.41 - output.height * 0.01, output.height * -0.06,
                  output.width * 0.41 - output.height * 0.01, output.height * -0.05);
    }
    output.popStyle();
    
    // Cloak activation gauge
    if(0 < ship.cloakActivation)
    {
      output.rect(output.width * -0.01, 0,  -output.width * 0.4 * ship.cloakActivation, output.height * 0.001);
      if(ship.cloaked)
      {
        // Label above gauge: "power conservation mode ACTIVE"
        cornerX = output.width * -0.41;
        cornerY = output.height * -0.01 - (hud_element_offline.height * textScale );
        output.image(hud_element_offline,
          cornerX, cornerY,
          hud_element_offline.width * textScale, hud_element_offline.height * textScale);
      }
    }
    // Label below gauge: "STEALTH CAPACITORS"
    cornerX = output.width * -0.01 - (hud_element_stealth.width * textScale );
    cornerY = output.height * 0.01;
    output.image(hud_element_stealth,
      cornerX, cornerY,
      hud_element_stealth.width * textScale, hud_element_stealth.height * textScale);
    
    // Super-gauge: Uptime
    output.pushMatrix();
    output.translate(output.width * -0.01, output.height * -0.013);
    for(int i = 1;  i <= story.tickTotal;  i *= 10)
    {
      output.rect(0, 0, output.width * -0.004, output.height * -0.002);
      output.translate(output.width * -0.006, 0.0);
    }
    output.popMatrix();
    
    /*
    //SET DRESSING
    
    output.fill(GUI_COLOR, 192 * cloakDim);
    
    // Draw targeting array down the left
    output.pushMatrix();
    output.translate(output.width * -0.41, output.height * -0.04);
    output.scale(0.5);
    output.textAlign(LEFT, BOTTOM);
    String targetingList = "";//"regional  space  survey \n    scan items";
    Iterator iShips = sceneShipManager.ships.iterator();
    iShips.next();
    while( iShips.hasNext() )
    {
      Ship s = (Ship) iShips.next();
      PVector pos = s.getRoot().getWorldPosition();
      String label = "\n" + s;
      label += "\n    " + pos.x;
      label += ",  " + pos.y;
      targetingList += label;
    }
    targetingList += "\n\nPRAScan\nregional  space  survey \n    scan items";
    output.text(targetingList, 0,0);
    output.popMatrix();
    
    
    // Draw movement block at right
    output.pushMatrix();
    output.translate(output.width * 0.41, output.height * -0.04);
    output.textAlign(RIGHT, BOTTOM);
    String textRight = "";
    // Draw fps
    textRight += int(frameRate) + "  fps\n";
    // Draw story time
    textRight += int(story.tickTotal) + "  clock cycles\n";
    textRight += int( millis() ) + "  ms  uptime\n";
    // Draw movement
    PVector playerPos = ship.getRoot().getWorldPosition();
    // Measuring in femtoparsecs, the screen is ~ 3km tall
    textRight += (int)playerPos.x + "  fpc\n" + (int)playerPos.y + "  fpc\n";
    textRight += (int)degrees( ship.getRoot().getWorldRotation() ) + "\n";
    // Draw artist name
    textRight += "MANTLE.mddn442.benjamin.d.richards.20130628\n";
    
    output.text(textRight, 0,0);
    
    output.popMatrix();
    */
    
    // COMPLETE
    output.popStyle();
    output.popMatrix();
    output.endDraw();
  }
  // drawHUD
  
}
// Hud
