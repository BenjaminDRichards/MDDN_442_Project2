/*
MANTLE asset pre-processor

By default, images coming out of Maya have no alpha channel data.
This pre-processor will take these images, combine them with an alpha map,
and save new versions of the file with the correct data automatically applied.
It will also perform the warp filter and save that too.
*/

import java.util.*;

void setup()
{
  size(1024,1024);
  
  ArrayList names = new ArrayList();
  names.add(  "Mantle_keel"  );
  names.add(  "Mantle_tail1"  );
  names.add(  "Mantle_tail2"  );
  names.add(  "Mantle_tail3"  );
  names.add(  "Mantle_tailL1"  );
  names.add(  "Mantle_tailL2"  );
  names.add(  "Mantle_tailL3"  );
  names.add(  "Mantle_tailR1"  );
  names.add(  "Mantle_tailR2"  );
  names.add(  "Mantle_tailR3"  );
  names.add(  "Mantle_tailTip"  );
  names.add(  "Mantle_turret"  );
  names.add(  "Mantle_wing1L"  );
  names.add(  "Mantle_wing1R"  );
  names.add(  "Mantle_wing2L"  );
  names.add(  "Mantle_wing2R"  );
  
  Iterator i = names.iterator();
  while( i.hasNext() )
  {
    String s = (String) i.next();
    String diffName = s + "_diff.png";
    String normName = s + "_norm.png";
    String alphaName = s + "_alpha.png";
    String warpName = s + "_warp.png";
    println(diffName + " " + normName + " " + alphaName + " " + warpName);
    
    // Get diffuse with alpha
    PGraphics diffOut = applyAlpha( loadImage(diffName), loadImage(alphaName) );
    //image(diffOut, 0,0);
    diffOut.save(diffName);
    
    // Get normal with alpha
    PGraphics normOut = applyAlpha( loadImage(normName), loadImage(alphaName) );
    //image(normOut, 0,0);
    normOut.save(normName);
    
    // Generate warp map
    PGraphics warpOut = normalToWarp(normOut, warpName);
    //image(warpOut, 0,0);
    warpOut.save(warpName);
  }
}

void draw()
{
  // White means it's done
  background(255);
}


PGraphics applyAlpha(PImage img, PImage alpha)
{
  PGraphics pg = createGraphics(img.width, img.height, JAVA2D);
  pg.beginDraw();
  pg.clear();
  pg.image(img, 0,0);
  pg.loadPixels();
  alpha.loadPixels();
  for(int i = 0;  i < pg.pixels.length;  i++)
  {
    color colImg = pg.pixels[i];
    color colAlpha = alpha.pixels[i];
    pg.pixels[i] = color( red(colImg), green(colImg), blue(colImg), alpha(colAlpha) );
  }
  pg.updatePixels();
  pg.endDraw();
  return( pg );
}
// applyAlpha



PGraphics normalToWarp(PImage normalSource, String name)
// Fuzz out the edges of a normal map to create nice warp falloff
// This was used to generate all the warp textures
{
  PGraphics warpBlur = createGraphics(normalSource.width, normalSource.height, JAVA2D);
  warpBlur.beginDraw();
  warpBlur.clear();
  // Fill with invisible flat-normals
  warpBlur.loadPixels();
  for(int i = 0;  i < warpBlur.pixels.length;  i++)
  {
    warpBlur.pixels[i] = color(127,127,255,0);
  }
  warpBlur.updatePixels();
  warpBlur.image(normalSource,  0, 0,  warpBlur.width, warpBlur.height);
  warpBlur.filter(BLUR, normalSource.width / 32.0);
  warpBlur.endDraw();
  
  PGraphics warpBlurBig = createGraphics(normalSource.width, normalSource.height, JAVA2D);
  warpBlurBig.beginDraw();
  warpBlurBig.clear();
  // Fill with invisible flat-normals
  warpBlurBig.loadPixels();
  for(int i = 0;  i < warpBlurBig.pixels.length;  i++)
  {
    warpBlurBig.pixels[i] = color(127,127,255,0);
  }
  warpBlurBig.updatePixels();
  warpBlurBig.image(normalSource,  0, 0,  warpBlurBig.width, warpBlurBig.height);
  warpBlurBig.filter(BLUR, normalSource.width / 16.0);
  warpBlurBig.endDraw();
  
  PGraphics warp = createGraphics(normalSource.width, normalSource.height, JAVA2D);
  warp.beginDraw();
  warp.clear();
  warp.image(normalSource,  0, 0,  warp.width, warp.height);
  warp.loadPixels();
  warpBlur.loadPixels();
  for(int i = 0;  i < warp.pixels.length;  i++)
  {
    color wCol = warp.pixels[i];
    color waCol = warpBlur.pixels[i];
    wCol = lerpColor(wCol, waCol, 1.0 - alpha(waCol) / 255.0);
    wCol = color( red(wCol), green(wCol), blue(wCol), 2.0 * alpha(wCol) - 255 );
    warp.pixels[i] = wCol;
  }
  warp.updatePixels();
  warp.endDraw();
  
  // Final composite
  warpBlurBig.beginDraw();
  warpBlurBig.image(warpBlur,  0, 0,  warpBlurBig.width, warpBlurBig.height);
  warpBlurBig.image(warp,  0, 0,  warpBlurBig.width, warpBlurBig.height);
  warpBlurBig.endDraw();
  
  //println("Warped " + name);
  //warpBlurBig.save("data/" + name);
  
  return( warpBlurBig );
}
// normalToWarp
