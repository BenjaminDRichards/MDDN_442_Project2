import java.util.*;


class BackgroundLearner
// This class learns the background and picks out objects moving against it.
{
  private Capture cam;
  private PVector RES;
  private PGraphics canvas, bgBuffer, bgBufferTemp, fgMask, fgIsolated, heat, heatIso;
  private boolean mirrorX, mirrorY;
  private float learnRate, learnTimer;
  private float canvasBlur;
  private float heatFade;
  private float heatIsoBlur;
  private float bgThreshold;  // How much difference before it registers?
  float pipHeight;            // Diagnostic display
  
  
  PShader shader_inputBlur;
  PShader shader_stripAlpha;
  PShader shader_maskFromBG;
  PShader shader_mult;
  PShader shader_addWhite;
  PShader shader_buildHeatIso;
  
  
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
    bgBufferTemp = createGraphics((int)RES.x, (int)RES.y, P2D);
    bgBufferTemp.beginDraw();  bgBufferTemp.clear();  bgBufferTemp.endDraw();
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
    
    // Load shaders
    shader_inputBlur = loadShader("shaders/camera/tex_inputBlur.frag.glsl", "shaders/camera/tex.vert.glsl");
    shader_stripAlpha = loadShader("shaders/camera/tex_stripAlpha.frag.glsl", "shaders/camera/tex.vert.glsl");
    shader_maskFromBG = loadShader("shaders/camera/tex_maskFromBG.frag.glsl", "shaders/camera/tex.vert.glsl");
    shader_mult = loadShader("shaders/camera/tex_mult.frag.glsl", "shaders/camera/tex.vert.glsl");
    shader_addWhite = loadShader("shaders/camera/tex_addWhite.frag.glsl", "shaders/camera/tex.vert.glsl");
    shader_buildHeatIso = loadShader("shaders/camera/tex_buildHeatIso.frag.glsl", "shaders/camera/tex.vert.glsl");
    
    // Set mirror options
    mirrorX = true;
    mirrorY = false;  // In case it's upside down...?
    
    // Set learn options
    canvasBlur = 0.01;
    learnRate = 0.01;  // How fast does it learn?
    learnTimer = 0;   // Tracker
    heatFade = 8.0;
    heatIsoBlur = 0.01;
    
    // Set threshold
    bgThreshold = 0.25;  // This might be important for localisation
                        // Perhaps load from external config file?
    
    // Set diagnostic size
    pipHeight = 64;    // Default, will be overridden
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
    
    
    // Fast initialise background
    if(frameCount < 2)
    {
      learnInstant();
    }
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
    bgBuffer.tint(255,255);
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
    learnRate = constrain(learnRate * amt, 0.0, 1.0);
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
    
    // Setup shader
    canvas.shader(shader_inputBlur);
    shader_inputBlur.set("blurStep",  canvasBlur * canvas.height / (float) canvas.width,  1.0 * canvasBlur);
    
    // Getting data
    canvas.image(cam, 0,0, canvas.width, canvas.height);
    
    // Fuzz the data a little bit
    //canvas.filter(BLUR, canvasBlur);
    
    // Complete
    canvas.resetShader();
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
      bgBufferTemp.beginDraw();
      
      // Apply learning
      bgBufferTemp.tint(255, 16);
      bgBufferTemp.image(canvas, 0,0, bgBuffer.width, bgBuffer.height);
      bgBufferTemp.resetShader();
      
      bgBufferTemp.endDraw();
      
      // Transfer to final map to assure alpha compliance
      bgBuffer.beginDraw();
      bgBuffer.shader(shader_stripAlpha);
      bgBuffer.image(bgBufferTemp, 0,0, bgBuffer.width, bgBuffer.height);
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
    
    fgMask.shader(shader_maskFromBG);
    shader_maskFromBG.set("background", bgBuffer);
    shader_maskFromBG.set("bgThreshold", bgThreshold);
    fgMask.image(canvas, 0,0, fgMask.width, fgMask.height);
    
    fgMask.endDraw();
  }
  // buildMask
  
  
  private void buildIsolation()
  // Apply mask to camera feed
  {
    fgIsolated.beginDraw();
    
    fgIsolated.shader(shader_mult);
    shader_mult.set("fgMask", fgMask);
    fgIsolated.image(canvas, 0,0, fgIsolated.width, fgIsolated.width);
    
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
    
    heat.shader(shader_addWhite);
    heat.image(fgMask, 0,0, heat.width, heat.height);
    heat.resetShader();
    
    heat.endDraw();
  }
  // buildHeat
  
  
  private void buildHeatIso()
  // Track movement that is temporally unique
  {
    heatIso.beginDraw();
    
    heatIso.shader(shader_buildHeatIso);
    shader_buildHeatIso.set("blurStep", heatIsoBlur * canvas.height / (float) canvas.width,  1.0 * heatIsoBlur);
    shader_buildHeatIso.set("fgMask", fgMask);
    heatIso.image(heat, 0,0, heatIso.width, heatIso.height);
    
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
    int frames = 6;
    PVector offsetSpacing = new PVector(8.0, 8.0);
    pipHeight = (height - (frames + 1) * offsetSpacing.y) / (float) frames;
    PVector displayRes = new PVector(width * pipHeight / (float)height, pipHeight);
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
