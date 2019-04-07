/**
 * Simple implementation of te painterly rendering
 * algorithm introduced by Hertzmann.
 *
 * This implementation only renders one layer of brushs. 
 * Uses the output as input for a new bruh width.
 *
 * http://www.mrl.nyu.edu/publications/painterly98/hertzmann-siggraph98.pdf
 * University of Constance-
 * Department for Computergraphics
 *
 * @author Thomas Lindemeier
 * @date 25.10.2012
 *
 */
import java.util.Collections;
import java.util.Vector;
import java.util.Iterator;

PImage sourceImage; // this is the image which should be rendered

PImage brushTexture;

PImage blurred; // this is the image used to grow strokes
PGraphics canvas; // offscreen buffer, used to render strokes
PImage colorDistance; // the difference between canvas and source
PImage render; // image to render in the window

int[] brushRadii = new int[] {32, 32, 32, 16, 16, 8, 8, 8, 5, 5, 5, 3, 3}; // used brushes
int brushIndex = -1;
int brushRadius = -1; // the radius of the brush 
final int areaError = 20; // the error threshold for the grid cells
final float FC = 0.5; // weight factor of the current direction vector used to integrate stroke
final int maxLength = 32; // max number of points in a stroke
final int minLength = 6;
float renderAlpha = 160.0f;

ArrayList<ErrorRegion> grid;

////////////////////////////////////////////////////////////
// compute euclidean color distance

float colorDistance(color c, color s) {
  return sqrt(sq(red(c)-red(s)) + sq(green(c)-green(s)) + sq(blue(c)-blue(s)));
}

void computeImageColorDistance(final PImage canvas, final PImage source) {                      
  canvas.loadPixels();
  source.loadPixels();
  for (int i = 0; i < source.pixels.length; ++i)
     colorDistance.pixels[i] = color(colorDistance(canvas.pixels[i], 
                                     source.pixels[i]));
}

void computeRegionColorDistance( final PImage canvas, 
                                 final PImage source, final ErrorRegion er) {
 
  for (int x = er.x0; x < source.width && x < er.x0+er.w; ++x)
    for (int y = er.y0; y < source.height && y < er.y0+er.h; ++y)
      colorDistance.pixels[x+y*source.width] = 
          color(colorDistance(canvas.pixels[x+y*source.width], 
                              source.pixels[x+y*source.width]));
}


////////////////////////////////////////////////////////////
/**
 * compute the direction with sobel operator
 */
 
PVector sobel(final PVector vec, final PImage source)
{
  PVector direction = new PVector();
  
  // directions can only be computed inside the image
  int x = constrain((int)vec.x,1,source.width-2);
  int y = constrain((int)vec.y,1,source.height-2);

  float tx = brightness(source.pixels[x+1 +(y-1)*source.width])
          +2*brightness(source.pixels[x+1 +(y)*source.width] )
            +brightness(source.pixels[x+1 +(y+1)*source.width])
            -brightness(source.pixels[x-1 +(y-1)*source.width] )
          -2*brightness(source.pixels[x-1 +(y)*source.width] )
            -brightness(source.pixels[x-1 +(y+1)*source.width]);
  float ty = brightness(source.pixels[x-1 +(y+1)*source.width]) 
          +2*brightness(source.pixels[x +(y+1)*source.width])
            +brightness(source.pixels[x+1 +(y+1)*source.width])
            -brightness(source.pixels[x-1 +(y-1)*source.width] )
          -2*brightness(source.pixels[x +(y-1)*source.width] )
            -brightness(source.pixels[x+1 +(y-1)*source.width]);
  
  // rotate vector about 90 degree
  direction.x = -ty;
  direction.y = tx;
  direction.z = sqrt(sq(direction.x) + sq(direction.y));
  direction.normalize();
  
  return direction;
}

////////////////////////////////////////////////////////////
/**
 * interpolates direction with runge kutta 4th order
 */
 
PVector traceStroke(final int x, final int y, 
                   final PImage source, PVector pv)
{
  // compute direction perpendicular to gradient 
  PVector v = sobel(new PVector(x, y), source);
  v.normalize();
  if (v.z == 0) return new PVector(0, 0, 0);

  if (pv == null) return v;
     else pv.normalize();

  // Hertzmann Painterly Rendering: if scalar 
  // product is less zero, reverse vector
  if (pv.x * v.x + pv.y * v.y < 0) {
    v.x *= -1;
    v.y *= -1;
  }
  // Hertzmann Painterly Rendering: filter 
  // stroke direction using previous vector
  float dx = FC * v.x + (1 - FC) * (pv.x);
  float dy = FC * v.y + (1 - FC) * (pv.y);
  v.x = dx / sqrt(dx*dx + dy*dy);
  v.y = dy / sqrt(dx*dx + dy*dy);      
  pv.x = v.x;
  pv.y = v.y;
  v.normalize();

  return v;
}

////////////////////////////////////////////////////////////
/**
 * render a stroke from a given seed point
 */
 
Stroke computeStroke(final PVector seed, PGraphics canvas, final PImage source)
{
  Stroke str = new Stroke();
  str.brushColor = source.get((int)seed.x, (int)seed.y);
  str.brushRadius = brushRadius;
  str.add(new PVector(seed.x, seed.y));

  PVector p = new PVector(seed.x, seed.y);
  // previous vector, used to interpolate direction
  PVector lastDir = sobel(seed, source); 
  
  // integrate stroke
  for (int i = 0; i < maxLength; ++i)
  {
    // if longer than min length and the canvas has already a good color on it than break;
    if ((i > minLength) 
      && (colorDistance(source.get((int)p.x, (int)p.y), canvas.get((int)p.x, (int)p.y))  
          <colorDistance(source.get((int)p.x, (int)p.y), str.brushColor)))
      return str;

    // find actual stroke direction by integration
    PVector direction = traceStroke((int)p.x, (int)p.y, source, lastDir);
    // if gradient is vanishing then stop
    if (direction.z == 0) 
    {
      direction.x = 1.f;
      direction.y = 0.f;
    }
    lastDir = direction;

    // step size is brush radius
    p.x += direction.x * brushRadius;
    p.y += direction.y * brushRadius;
    str.add(new PVector(p.x, p.y)); 
  }
  return str;
}

////////////////////////////////////////////////////////////
// compute the seeding grid
// @param r brush radius -> cell size
// @param w the width of the input image
// @param h the height of the input image
////////////////////////////////////////////////////////////
 
ArrayList<ErrorRegion> computeGrid(int r, int w, int h) {
  ArrayList<ErrorRegion> regions = new ArrayList<ErrorRegion>((w/r) * (h/r));

  for (int x = 0; x < w; x+=r) {
    for (int y = 0; y < h; y+=r) {
      regions.add(new ErrorRegion(x, y, r, r, 0));
    }
  }

  return regions;
}

////////////////////////////////////////////////////////////
//
// reduces the brush size and draws the next layer
//
////////////////////////////////////////////////////////////

void nextLayer()
{
  // next layer
  brushIndex++;   
  if (brushIndex >= brushRadii.length) return;
  brushRadius = brushRadii[brushIndex];
  println("changing brush to width: " + brushRadius*2);

  // blur according to brush size
  blurred = sourceImage.get();
  blurred.filter(BLUR, brushRadius);  

  // compute error grids
  grid = computeGrid(brushRadius, blurred.width, blurred.height);

  // compute the color distance between canvas and source image
  computeImageColorDistance(canvas, blurred);

  //compute the average error of each grid cell 
  for (ErrorRegion er : grid)
    er.computeAverageDistance(colorDistance);
}

////////////////////////////////////////////////////////////
//
// main routines
//
////////////////////////////////////////////////////////////

void draw() 
{
  // brush iteration
  canvas.loadPixels();
  nextLayer();

  if ((brushRadius <= 0) || (brushIndex >= brushRadii.length))
  { // layers are finished
    image(render, 0, 0);
    return;
  }
  
  // paint next stroke in current error cell
  canvas.beginDraw();
  for (ErrorRegion er : grid) {

    // compute the color distance between canvas and 
    // source image in the error cell
    computeRegionColorDistance(canvas, blurred, er);
    er.computeAverageDistance(colorDistance);

    // if not enough average error in grid 
    if (er.ae < areaError) continue;

    // generate stroke
    PVector seedp = er.computeSeedPoint(colorDistance);
    Stroke str = computeStroke(seedp, canvas, blurred);

    //draw stroke   
    str.render(canvas);
    //str.renderTextured(canvas);
  } 
  canvas.endDraw();
  image(render, 0, 0);
}

////////////////////////////////////////////////////////////

void setup()
{
  // Photo by Mat Reding on Unsplash
  sourceImage = loadImage("data/mat-reding-1400097-unsplash.jpg");  
  sourceImage.resize(864, 1296);
  
  brushTexture = loadImage("data/brush.png");

  size(864, 1296, P2D); // size must always have fixed parameters...
  
  canvas = createGraphics(sourceImage.width, sourceImage.height, P2D);
  canvas.beginDraw();
    canvas.background(255);
    canvas.noFill(); 
    canvas.strokeCap(ROUND); // make round caps
    canvas.strokeJoin(ROUND); // let the strokes join round
  canvas.endDraw();
  
  colorDistance = createImage(sourceImage.width, sourceImage.height, RGB); 

  render = canvas;
  background(255);
}

////////////////////////////////////////////////////////////

void keyPressed()
{
  if (key == '1') render = sourceImage;
  if (key == '2') render = canvas;
  if (key == '3') render = colorDistance;
  if (key == '4') render = blurred;
  if (key == 's') canvas.save("data/result.jpg");
}
