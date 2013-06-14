import java.util.*;


class BackgroundLearner
// This class learns the background and picks out objects moving against it.
{
  private Capture cam;
  private PVector RES;
  private PGraphics canvas, bgBuffer, fgMask, fgIsolated, heat, heatIso;
  private boolean mirrorX, mirrorY;
  private float learnRate, learnTimer;
  private float canvasBlur;
  private float heatFade;
  private float heatIsoBlur;
  private float bgThreshold;  // How much difference before it registers?
  
  BackgroundLearner(Capture cam)
  {
    // Get camera feed
    this.cam = cam;
    
    // Setup canvas
    RES = new PVector(160, 120);
    // Temp graphics
    canvas = createGraphics((int)RES.x, (int)RES.y, P2D);
    canvas.beginDraw();  canvas.clear();  canvas.endDraw();
    bgBuffer = createGraphics((int)RES.x, (int)RES.y, P2D);
    bgBuffer.beginDraw();  bgBuffer.clear();  bgBuffer.endDraw();
    fgMask = createGraphics((int)RES.x, (int)RES.y, P2D);
    fgMask.beginDraw();  fgMask.clear();  fgMask.endDraw();
    fgIsolated = createGraphics((int)RES.x, (int)RES.y, P2D);
    fgIsolated.beginDraw();  fgIsolated.clear();  fgIsolated.endDraw();
    heat = createGraphics((int)RES.x, (int)RES.y, P2D);
    heat.beginDraw();  heat.clear();  heat.endDraw();
    heatIso = createGraphics((int)RES.x, (int)RES.y, P2D);
    heatIso.beginDraw();  heatIso.clear();  heatIso.endDraw();
    // True graphics
    setupCanvases();
    
    // Set mirror options
    mirrorX = true;
    mirrorY = false;  // In case it's upside down...?
    
    // Set learn options
    canvasBlur = 1.0;
    learnRate = 0.01;  // How fast does it learn?
    learnTimer = 0;   // Tracker
    heatFade = 32.0;
    heatIsoBlur = 5.0;
    
    // Set threshold
    bgThreshold = 0.25;  // This might be important for localisation
                        // Perhaps load from external config file?
  }
  
  
  public void run()
  // Updates the output graphics from the camera
  {
    // Dump pixels into canvas
    fillCanvas();
    
    // Run background learner
    runLearn();
    
    // Create foreground mask
    buildMask();
    
    // Apply foreground mask
    buildIsolation();
    
    // Update heat map
    buildHeat();
    
    // Update heat isolator
    buildHeatIso();
  }
  // run
  
  
  public PImage getCanvas()
  // Returns the canvas
  {
    return( canvas );
  }
  // getCanvas
  
  
  public PImage getBackgroundBuffer()
  // Returns the learning buffer
  {
    return( bgBuffer );
  }
  // getBackgroundBuffer
  
  
  public PImage getForegroundMask()
  // Returns the difference mask
  {
    return( fgMask );
  }
  // getForegroundMask
  
  
  public PImage getForeground()
  // Returns the isolated foreground
  {
    return( fgIsolated );
  }
  // getForeground
  
  
  public PImage getHeat()
  // Returns the latest heat map
  {
    return( heat );
  }
  // getHeat
  
  
  public PImage getHeatIso()
  // Returns the isolated heat map
  {
    return( heatIso );
  }
  // getHeatIso
  
  
  public void learnInstant()
  // Instantly overwrites the learning buffer
  {
    bgBuffer.beginDraw();
    
    bgBuffer.clear();
    bgBuffer.image(canvas, 0,0, bgBuffer.width, bgBuffer.height);
    
    bgBuffer.endDraw();
  }
  // learnInstant
  
  
  public void slideCanvasBlur(float amt)
  {
    canvasBlur = max(canvasBlur + amt, 0.0);
  }
  
  
  public void slideLearnRate(float amt)
  {
    learnRate = constrain(learnRate + amt, 0.0, 1.0);
  }
  
  
  public void slideBackgroundThreshold(float amt)
  {
    bgThreshold = constrain(bgThreshold + amt, 0.0, 1.0);
  }
  
  
  public void slideHeatFade(float amt)
  {
    heatFade = constrain(heatFade + amt, 0.0, 255.0);
  }
  
  
  public void slideHeatIsoBlur(float amt)
  {
    heatIsoBlur = max(heatIsoBlur + amt, 0.0);
  }
  
  
  private void fillCanvas()
  // Dumps pixels from camera to canvas
  {
    canvas.beginDraw();
    canvas.pushMatrix();
    
    // Mirroring
    PVector pos = new PVector(0,0,0);
    PVector sz = new PVector(1,1);
    if(mirrorX)
    {
      pos.set( canvas.width, pos.y, 0 );
      sz.set( -1, sz.y );
    }
    if(mirrorY)
    {
      pos.set( pos.x, canvas.height, 0 );
      sz.set( sz.x, -1 );
    }
    canvas.translate(pos.x, pos.y);
    canvas.scale(sz.x, sz.y);
    
    // Getting data
    canvas.image(cam, 0,0, canvas.width, canvas.height);
    
    // Fuzz the data a little bit
    canvas.filter(BLUR, canvasBlur);
    
    // Complete
    canvas.popMatrix();
    canvas.endDraw();
  }
  // fillCanvas
  
  
  private void runLearn()
  // Build background buffer
  {
    learnTimer += learnRate;
    
    if(1 <= learnTimer)
    {
      bgBuffer.beginDraw();
      
      // Apply learning
      bgBuffer.tint(255, 16);
      bgBuffer.image(canvas, 0,0, bgBuffer.width, bgBuffer.height);
      
      // Restore alpha
      // Because otherwise, alpha gets blended onto the canvas, turning it transparent.
      bgBuffer.loadPixels();
      for(int i = 0;  i < bgBuffer.pixels.length;  i++)
      {
        color col = bgBuffer.pixels[i];
        col = color(red(col), green(col), blue(col), 255);
        bgBuffer.pixels[i] = col;
      }
      bgBuffer.updatePixels();
      
      bgBuffer.endDraw();
      
      // Deiterate
      learnTimer -= 1;
    }
  }
  // runLearn
  
  
  private void buildMask()
  // Builds the foreground mask by background comparison
  {
    fgMask.beginDraw();
    
    // Perform permutations
    // Take the learned background...
    fgMask.image(bgBuffer, 0,0, fgMask.width, fgMask.height);
    // ...subtract the live feed...
    fgMask.blend(canvas,  0,0, canvas.width, canvas.height,  0,0, fgMask.width, fgMask.height,  DIFFERENCE);
    // ...and snap it to black and white.
    fgMask.filter(THRESHOLD, bgThreshold);
    
    fgMask.endDraw();
  }
  // buildMask
  
  
  private void buildIsolation()
  // Apply mask to camera feed
  {
    fgIsolated.beginDraw();
    
    fgIsolated.image(canvas,  0,0,  fgIsolated.width, fgIsolated.height);
    fgIsolated.blend(fgMask,  0,0, fgMask.width, fgMask.height,  0,0,
      fgIsolated.width, fgIsolated.height,  MULTIPLY);
    
    fgIsolated.endDraw();
  }
  // buildIsolation
  
  
  private void buildHeat()
  // Track motion over time
  {
    heat.beginDraw();
    
    // Fade over time
    heat.fill(0, heatFade);
    heat.noStroke();
    heat.rect(0,0, heat.width, heat.height);
    
    // Apply current mask
    heat.blend(fgMask, 0,0, fgMask.width, fgMask.height,  0,0, heat.width, heat.height,  SCREEN);
    //heat.tint(255,64);
    //heat.image(fgMask, 0,0, heat.width, heat.height);
    
    // Blur out
    //heat.filter(BLUR, 5);
    
    // Restore alpha
    // Because otherwise, alpha gets blended onto the canvas, turning it transparent.
    heat.loadPixels();
    for(int i = 0;  i < heat.pixels.length;  i++)
    {
      color col = heat.pixels[i];
      col = color(red(col), green(col), blue(col), 255);
      heat.pixels[i] = col;
    }
    heat.updatePixels();
    
    heat.endDraw();
  }
  // buildHeat
  
  
  private void buildHeatIso()
  // Track movement that is temporally unique
  {
    heatIso.beginDraw();
    
    // Lay down learned background
    heatIso.image(heat, 0,0, heatIso.width, heatIso.height);
    // Apply contemporary differential
    heatIso.blend(fgMask, 0,0, fgMask.width, fgMask.height, 0,0, heatIso.width, heatIso.height, DIFFERENCE);
    // Apply blur
    heatIso.filter(BLUR, heatIsoBlur);
    
    heatIso.endDraw();
  }
  // buildHeatIso
  
  
  private void setupCanvases()
  // Prepare buffers
  {
    // Setup desired resolution
    int x = (int)RES.x;
    int y = (int)RES.y;
    
    // Init transformed source canvas
    canvas = createGraphics(x, y, P2D);
    canvas.beginDraw();
    canvas.image(cam,0,0);
    canvas.endDraw();
    
    // Init buffer space
    bgBuffer = createGraphics(x, y, P2D);
    bgBuffer.beginDraw();
    bgBuffer.image(canvas, 0,0);
    bgBuffer.endDraw();
    
    // Init mask
    fgMask = createGraphics(x, y, P2D);
    fgMask.beginDraw();
    fgMask.background(0);
    fgMask.endDraw();
    
    // Init isolation pass
    fgIsolated = createGraphics(x, y, P2D);
    fgIsolated.beginDraw();
    fgIsolated.background(0);
    fgIsolated.endDraw();
    
    // Init heat map
    heat = createGraphics(x, y, P2D);
    heat.beginDraw();
    heat.background(0);
    heat.endDraw();
    
    // Init heat isolation map
    heatIso = createGraphics(x, y, P2D);
    heatIso.beginDraw();
    heatIso.background(0);
    heatIso.endDraw();
  }
  // setupCanvases
  
  
  public void diagnoseBuffers()
  // Draw buffers to the screen
  {
    pushMatrix();
    pushStyle();
    PVector offsetSpacing = new PVector(8.0, 8.0);
    PVector displayRes = new PVector(160, 120);
    fill(255);
    textAlign(LEFT, TOP);
    translate(offsetSpacing.x, 0);
    
    ArrayList bufferList = new ArrayList();
    ArrayList bufferListLabels = new ArrayList();
    bufferList.add(canvas);      bufferListLabels.add("Canvas: raw colour feed \nMirrorXY " + mirrorX + ", " + mirrorY + "\nBlur " + canvasBlur + "\nTumble '1'");
    bufferList.add(bgBuffer);    bufferListLabels.add("Learned background buffer \nPress L to refresh buffer \nLearn rate " + learnRate + "\nTumble '2'");
    bufferList.add(fgMask);      bufferListLabels.add("Foreground mask \nThreshold " + bgThreshold + "\nTumble '3'");
    bufferList.add(fgIsolated);  bufferListLabels.add("Foreground mask, isolated");  // No controls
    bufferList.add(heat);        bufferListLabels.add("Heat map \nFade " + heatFade + "\nTumble '4'");
    bufferList.add(heatIso);     bufferListLabels.add("Heat map, isolated \nBlur " + heatIsoBlur + "\nTumble '5'");
    
    Iterator i = bufferList.iterator();
    Iterator iText = bufferListLabels.iterator();
    while( i.hasNext() )
    {
      PGraphics pg = (PGraphics) i.next();
      String label = (String) iText.next();
      translate(0, offsetSpacing.y);
      image(pg, 0,0, displayRes.x, displayRes.y);
      text(label, 0,0);
      translate(0, displayRes.y);
    }
    popMatrix();
    popStyle();
  }
}
// BackgroundLearner
