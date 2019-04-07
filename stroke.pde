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
class Stroke implements Iterable<PVector>
{
  public color brushColor = color(0, 0, 0);
  public float brushRadius = 16;
  // control points of the stroke
  private Vector<PVector> points = new Vector<PVector>(); 
  
  Stroke() {}

  void add(int x, int y) { points.add(new PVector(x, y)); }

  public int size() { return points.size(); }

  void add(PVector vec) { points.add(vec); }

  void clear() { points.clear(); }

  Iterator<PVector> iterator() { return points.iterator(); }

  void render(final PGraphics pg)  {  
    pg.noFill();
    pg.smooth();
    pg.strokeCap(ROUND); // make round caps
    pg.strokeJoin(ROUND); // let the strokes join round
    
    color c = color(red(brushColor), green(brushColor), blue(brushColor), renderAlpha);
    pg.stroke(c);
    pg.strokeWeight(2*brushRadius);
    pg.beginShape();
    for (PVector p : this)
      pg.vertex(p.x, p.y);
    pg.endShape();
  }
  
  void renderTextured(final PGraphics pg)
  {
    color c = color(red(brushColor), green(brushColor), blue(brushColor), renderAlpha);
    pg.stroke(c);
    pg.fill(c);
    pg.strokeWeight(1);
    // short stroke
    if (points.size() < 2) 
    {
      if (points.isEmpty()) return;
      PVector p = points.get(0);
      pg.ellipse(p.x, p.y, 2*brushRadius, 2*brushRadius);
      return;
    }

    pg.noStroke();
    pg.noFill();
    // draw start 
    PVector p0;
    PVector p1;
    PVector p2;
    float mag, dx, dy, dist;

    // compute total length of stroke
    float strokeLength = 0;
    for (int i=0; i < points.size() - 1; ++i)
    {
      p0 = points.get(i);
      p1 = points.get(i+1);

      strokeLength += sqrt((p1.x-p0.x)*(p1.x-p0.x)+(p1.y-p0.y)*(p1.y-p0.y));
    }

    p0 = points.get(0);
    p1 = points.get(1);

    dx = p1.y - p0.y;
    dy = p0.x - p1.x;

    mag = sqrt(dx*dx + dy*dy);

    dx /= mag;
    dy /= mag;

    float textureU = 0;
    float textureV = 0;
    
    pg.textureMode(IMAGE);
    final int tw = brushTexture.width;
    final int th = brushTexture.height;
    pg.beginShape(TRIANGLE_STRIP);

    //brush texture
    pg.texture(brushTexture);
    pg.tint(brushColor);
   
    pg.vertex(p0.x + brushRadius * dx, p0.y + brushRadius * dy, textureU*tw, 0);
    pg.vertex(p0.x - brushRadius * dx, p0.y - brushRadius * dy, textureU*tw, th);

    //draw middle stroke
    for (int i=1; i < points.size() - 1; ++i)
    {
      p0 = points.get(i-1);
      p1 = points.get(i);
      p2 = points.get(i+1);
            
      // (p1-p2) and rotate 90 degrees
      dx = p2.y - p0.y;
      dy = p0.x - p2.x;

      mag = sqrt(dx*dx + dy*dy);

      dx /= mag;
      dy /= mag;

      dist = sqrt((p1.x-p0.x)*(p1.x-p0.x)+(p1.y-p0.y)*(p1.y-p0.y));
      textureU += dist / strokeLength;

      pg.vertex(p1.x + brushRadius * dx, p1.y + brushRadius * dy, textureU*tw, 0);
      pg.vertex(p1.x - brushRadius * dx, p1.y - brushRadius * dy, textureU*tw, th);
    }

    //draw end 
    p0 = points.get(points.size()-2);
    p1 = points.get(points.size()-1);

    dx = p1.y - p0.y;
    dy = p0.x - p1.x;

    mag = sqrt(dx*dx + dy*dy);

    dx /= mag;
    dy /= mag;

    dist = sqrt((p1.x-p0.x)*(p1.x-p0.x)+(p1.y-p0.y)*(p1.y-p0.y));
    textureU += dist / strokeLength;

    pg.vertex(p1.x + brushRadius * dx, p1.y + brushRadius * dy, textureU*tw, 0);
    pg.vertex(p1.x - brushRadius * dx, p1.y - brushRadius * dy, textureU*tw, th);

    pg.endShape();  
  }
}
