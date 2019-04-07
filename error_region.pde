/**
 * 
 *
 * University of Constance-
 * Department for Computergraphics
 *
 * @author Thomas Lindemeier
 * @date 28.10.2012
 *
 */

class ErrorRegion
{
  int x0, y0, w, h;
  float ae;

  ErrorRegion(int px, int py, int pw, int ph, float pae) {
    x0 = px;
    y0 = py;
    w = pw;
    h = ph;
    ae = pae;
  }
  
  PVector computeSeedPoint(final PImage distance) {
    PVector seed = new PVector();
    float errorMax = 0;
    float error;
    int index;
    
    for (int x = x0; x < x0+w; x++) 
      for (int y = y0; y < y0+h; y++) {        
        index = x + y * distance.width;
        if (index < distance.pixels.length) {
           error = red(distance.pixels[index]);
           if (error > errorMax){
             errorMax = error;
             seed.x = x;
             seed.y = y;
           }
        }
      }
    return seed;
  }

  void computeAverageDistance(final PImage distance) {   
    ae = 0;
    int index;
    int totalPixels = 0;
    for (int x=x0; x<x0+w; x++) 
      for (int y=y0; y<y0+h; y++) {
        index = x + y * distance.width;
        if (index < distance.pixels.length) {
          ae += red(distance.pixels[index]);
          totalPixels++;
        }
      }
    ae /= totalPixels;
  }
}
