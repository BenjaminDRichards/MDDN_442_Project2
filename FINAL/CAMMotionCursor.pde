class MotionCursor
// Tracks a BW mask to position a cursor
{
  private PVector cPos;          // Cursor position
  private float cLerp;           // Speed with which cursor approaches motion
  private PVector jPos;          // Jitter cursor position
  private PImage src;            // Source image feed
  private float THRESH_REL;      // Proportion of image required to get a reliable fix
  private float THRESH_BRI;      // Level at which pixels get counted
  private PGraphics selBuffer;   // Buffer for motion visualisation
  private PGraphics selTarget;   // Target for rendering motion visualisation
  private boolean selDraw;       // Do we draw the motion vis?
  private PShader shaderMoVis;   // Accelerated high-quality visualiser
  float pipHeight;               // Diagnostic display parameter
  
  MotionCursor()
  {
    // Setup defaults
    cPos = new PVector(0,0,0);
    jPos = cPos.get();
    cLerp = 0.05;
    THRESH_REL = 0.01;
    THRESH_BRI = 0.50;
    
    // Setup motion visualisation
    selBuffer = createGraphics(160, 120, P2D);
    selTarget = g;
    selDraw = true;
    shaderMoVis = loadShader("shaders/camera/tex_motionVisualiser.frag.glsl", "shaders/camera/tex.vert.glsl");
    pipHeight = 64;    // Default, will be overridden
  }
  
  
  public void run(PImage src)
  // Track motion and comply cursor position
  {
    // Load source image
    this.src = src;
    
    // Analyse the image
    PVector jitterPos = getCenter();
    if(0 < jitterPos.z)
    {
      // That is, we got a reliable update
      jPos = getCenter();
    }
    
    // Update cursor
    updateCursor();
    
    
    // Motion visualisation
    if(selDraw)
      doMoVis();
  }
  // run
  
  
  public PVector getCursor()
  // Returns a vector of the current cursor position
  {
    return( cPos );
  }
  // getCursor
  
  
  public PVector getCursorNormalized()
  // Returns a vector in range 0-1 in both dimensions
  // Good for resolution-agnostic results
  {
    return( new PVector(cPos.x / (float) src.width,  cPos.y / (float) src.height, 0) );
  }
  // getCursorNormalized
  
  
  public PVector getJCursor()
  // Returns a vector of the current jitter position
  {
    return( jPos );
  }
  // getCursor
  
  
  public PVector getJCursorNormalized()
  // Returns a vector in range 0-1 in both dimensions
  // Good for resolution-agnostic results
  {
    return( new PVector(jPos.x / (float) src.width,  jPos.y / (float) src.height, 0) );
  }
  // getJCursorNormalized
  
  
  public PImage getSelBuffer()
  // Returns the selection visualiser buffer
  {
    return( selBuffer );
  }
  // getSelBuffer
  
  
  public void setDrawTarget(PGraphics pg)
  // Sets the draw target
  {
    selTarget = pg;
  }
  // setDrawTarget
  
  
  public void renderMoVis()
  // Renders the motion visualisation
  {
    // Style MoVis
    selTarget.pushStyle();
    selTarget.noFill();
    
    // Determine scale factor
    float sx = selTarget.width / (float) selBuffer.width;
    float sy = selTarget.height / (float) selBuffer.height;
    
    // Shader border detection
    selTarget.shader(shaderMoVis);
    selTarget.tint(GUI_COLOR);
    shaderMoVis.set("resolution", (float)selBuffer.width, (float)selBuffer.height);
    selTarget.image(selBuffer, 0,0, selTarget.width, selTarget.height);
    selTarget.resetShader();
    
    // Render cursor
    float offset = selTarget.height * 64.0 / 720.0;
    selTarget.pushMatrix();
    selTarget.translate(cPos.x * sx - offset, cPos.y * sy - offset);
    selTarget.tint(GUI_COLOR, 127);
    selTarget.image(hud_reticule, 0,0, offset * 2, offset * 2);
    
    // Label cursor
    selTarget.translate(offset, offset);  // Go to the center of the reticule
    selTarget.scale(0.5);
    selTarget.fill(GUI_COLOR, 127);
    selTarget.textAlign(LEFT, TOP);
    String coords = (cPos.x - 0.5 * selBuffer.width) + "\n" + (cPos.x - 0.5 * selBuffer.height);
    selTarget.text( coords, 0, 0 );
    selTarget.popMatrix();
    
    selTarget.popStyle();
  }
  // renderMoVis
  
  
  private void updateCursor()
  // Moves the cursor after the jitter cursor
  {
    float dx = lerp(cPos.x, jPos.x, cLerp);
    float dy = lerp(cPos.y, jPos.y, cLerp);
    cPos.set(dx, dy, 0);
  }
  // updateCursor
  
  
  private PVector getCenter()
  // Gets the average white pixel position
  {
    src.loadPixels();
    
    // Running totals
    float sX = 0;
    float sY = 0;
    float sN = 0;
    
    // Check all pixels
    for(int i = 0;  i < src.pixels.length;  i++)
    {
      if( 255 * THRESH_BRI < red(src.pixels[i]) )
      {
        // That is, it's on the white side
        // Compute position
        int x = floor(i % src.width);
        int y = floor(i / (float)src.width);
        // Update running totals
        sX += x;
        sY += y;
        sN += 1;
      }
      // Else don't count it
    }
    
    // Test for valid result
    float reliability = 0;
    if( THRESH_REL < sN / (float)src.pixels.length )
    {
      // That is, there's a lot of data on the screen so it's probably not just noise
      reliability = 1;
    }
    
    // Build vector
    PVector sPos = new PVector(sX / sN,  sY / sN,  reliability);
    
    return( sPos );
  }
  // getCenter
  
  
  private void doMoVis()
  // Do motion visualisation
  {
    // Setup movis if necessary
    if(src.width != selBuffer.width  ||  src.height != selBuffer.height)
    {
      // That is, non-compliant resolutions
      selBuffer = createGraphics(src.width, src.height, P2D);
      println("Resized MoVis buffer to comply with source.");
    }
    
    // Dump and threshold source
    selBuffer.beginDraw();
    
    selBuffer.image(src, 0,0, selBuffer.width, selBuffer.height);
    selBuffer.filter(THRESHOLD, THRESH_BRI);
    
    selBuffer.endDraw();
  }
  // doMoVis
  
  
  public void diagnose()
  // Display moVis on main display
  {
    pushMatrix();
    pushStyle();
    
    PVector displayRes = new PVector(width * pipHeight / (float)height, pipHeight);
    
    fill(255);
    textAlign(LEFT, TOP);
    translate(displayRes.x + 8.0 * 2, 8.0);
    image(selBuffer, 0,0, displayRes.x, displayRes.y);
    text("Motion visualisation \nBrightness(6) " + (THRESH_BRI * 255.0) + "\nActivity(7) " + THRESH_REL, 0,0);
    
    popMatrix();
    popStyle();
  }
  // diagnose
  
  
  public void slideThresholdBrightness(float amt)
  {
    THRESH_BRI = constrain(THRESH_BRI + amt, 0.0, 1.0);
  }
  
  
  public void slideThresholdReliability(float amt)
  {
    THRESH_REL = constrain(THRESH_REL + amt, 0.0, 1.0);
  }
  
}
// MotionCursor
