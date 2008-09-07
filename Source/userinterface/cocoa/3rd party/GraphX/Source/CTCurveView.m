//
//  CTCurveView.m
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//



#import "CTCurveView.h"

@implementation CTCurveView

@synthesize resolution;
@synthesize approximateOnLiveResize;

@synthesize showCurve;
@synthesize showFill;

- (id)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect]) != nil)
  {
    //Set Default Resolution for X (in terms of pixel coordinates - **not in terms of a data value)
    resolution = 1;
    drawingResolution = 1;
    approximateOnLiveResize = NO;
    
    //Set Default Colors
    [graphColors setColor:[ NSColor blackColor ] forKey:@"curve"];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"fill"];
    
    
    //Set Flags
    showCurve = YES;
    showFill  = YES;

    
    //Set Drawing Constants
    curveLineWidth = 2;
      
    curve        = [[NSBezierPath alloc] init];
    displacement = [[NSBezierPath alloc] init];
    
    [curve setLineWidth:curveLineWidth];
    [curve setLineJoinStyle:NSRoundLineJoinStyle];
    [curve setLineCapStyle :NSRoundLineCapStyle ];
    
    [curve        setCachesBezierPath:YES];
    [displacement setCachesBezierPath:YES];
  }
  
  return self;
}

- (void)dealloc
{
  [curve release];
  [displacement release];
  
  [super dealloc];
}


- (void)drawGraph:(NSRect)rect
{
  if (!dataSource)
    return;

  [NSGraphicsContext saveGraphicsState];
  NSRectClip(rect);
  
  const float maxXBounds = NSMaxX(rect);  //bounds of graph - stored as constants
  const float minXBounds = NSMinX(rect);  // for preformance reasons(used often)
  const float maxYBounds = NSMaxY(rect);
  const float minYBounds = NSMinY(rect);
  
  const float xRatio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ÆData/ÆCoordinate -> dg/dx
  const float yRatio = (yMax - yMin)/(maxYBounds - minYBounds); //ratio ÆData/ÆCoordinate -> dh/dy
  
  const float xOrigin = (0 - xMin)/(xRatio) + minXBounds; //x component of the origin
  const float yOrigin = (0 - yMin)/(yRatio) + minYBounds; //y component of the origin
  
  //Create Curve Path then Draw Curve and Fill Area underneath
  
  //start by convert drawingResolution(a pixel increment) to gres(a graph value increment)
  // this uses a method similar to the linear transformation from above(drawing the xgrid)
  float gres = drawingResolution * (xMax - xMin)/(maxXBounds - minXBounds);
  if (gres <= 0)
    gres = 1.0;

  //will now start sampling graph values to form graph points, then converting them to pixel points,
  //and finally feeding them into the curve
  //
  //Sampling will begin at xMin and finish off at xMax
  //  any points that return null will be ignored
  
  //the sample data point's coordinates
  float g = xMin - gres;
  float h = NAN; 
  
  float g_next;
  float h_next;
  
  float gMinRatio = xMin/xRatio;
  float hMinRatio = yMin/yRatio;
  
  float x;
  float y;
  
  while (g < xMax)
  {
    //NaN Segment (keep continuing until a graphable point is reached)
    while(g < xMax && isnan(h))
    {
      g_next = g + gres;
      h_next = [dataSource yValueForXValue:g_next];
      
      if (isnan(h_next))
      {
      }
      //If the NaN Segment has ended - begin drawing points
      else
      {
        x = (g_next)/(xRatio) - gMinRatio + minXBounds;
        
        if(isfinite(h_next))              //move to the right to the point
          y = (h_next)/(yRatio) - hMinRatio + minYBounds;
        else if (signbit(h_next))            //move to top of screen
          y = maxYBounds + curveLineWidth;
        else                      //move to bottom of screen
          y = minYBounds - curveLineWidth;
          
        [curve moveToPoint:NSMakePoint(x, y)];
      }
      
      g = g_next;
      h = h_next;
    }
    
    //Make sure we aren't ending with NaN
    if (g >= xMax && isnan(h))
      break;
    
    float firstPoint = g/(xRatio) - gMinRatio + minXBounds;
    [delegate hasDrawnFirstSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,y) inRect:rect withOrigin:NSMakePoint(xOrigin,yOrigin)];
    
    
    //Graphable Line Segment continue until NaN segment is once again reached
    while (!isnan(h))
    {
      while (g < xMax && isfinite(h))
      {
        g_next = g + gres;
        h_next = [dataSource yValueForXValue:g_next];
        
        [delegate hasDrawnSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,y) inRect:rect withOrigin:NSMakePoint(xOrigin,yOrigin)];
        
        if (isnan(h_next))
        {
          break;
        }
        //Next point is valid - draw a line to it
        else
        {
          
          if (isfinite(h_next))              //line to the right to the point
          {
            x = (g_next)/(xRatio) - gMinRatio + minXBounds;
            y = (h_next)/(yRatio) - hMinRatio + minYBounds;
          }
          else if(signbit(h_next))            //line to top of screen
            y = maxYBounds + curveLineWidth;
          else                      //line to bottom of screen
            y = minYBounds - curveLineWidth;
          
          
          [curve lineToPoint:NSMakePoint(x,y)];
        }
        
        g = g_next;
        h = h_next;
      }
      
      while(!isfinite(h) && !isnan(h) && g <= xMax)
      {
        g_next = g + gres;
        h_next = [dataSource yValueForXValue:g_next];
        
        [delegate hasDrawnSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,h) inRect:rect withOrigin:NSMakePoint(xOrigin,yOrigin)];
        
        if (isnan(h_next))
        {
          break;
        }
        //Next point is valid - draw a line to it
        else if (!isnan(h_next))
        {
          x = g_next / xRatio - gMinRatio + minXBounds;
          y = signbit(h) ? maxYBounds + curveLineWidth : minYBounds - curveLineWidth;
          
          [curve lineToPoint:NSMakePoint(x,y)];
          
          //Next point is valid - draw a line to it
          x = g_next / xRatio - gMinRatio + minXBounds;
          
          if (isfinite(h_next))              //move to the right to the point
            y = h_next / yRatio - hMinRatio + minYBounds;
          else if (signbit(h_next))            //move to top of screen
            y = maxYBounds + curveLineWidth;
          else                      //move to bottom of screen
            y = minYBounds - curveLineWidth;
            
          [curve lineToPoint:NSMakePoint(x, y)];
        }
        
        g = g_next;
        h = h_next;
      }
        
      if (isnan(h_next) || g >= xMax)
        break;
    }
    
    [delegate hasDrawnLastSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,y) inRect:rect withOrigin:NSMakePoint(xOrigin,yOrigin)];
    
    //Set points up for next segment
    g = g_next;
    h = h_next;
    
    if (showFill)
    {
      //Create New path that wil be filled
      [displacement appendBezierPath:curve];
      
      //move curve to x axis, then go across it to the begining of the segment
      [displacement lineToPoint:NSMakePoint(x, yOrigin)];
      [displacement lineToPoint:NSMakePoint(firstPoint, yOrigin)];
      
      //fill area under curve
      [[graphColors colorWithKey:@"fill"] set];
      [displacement fill];
    }

    //Draw and fill curve
    if (showCurve)
    {
      [[graphColors colorWithKey:@"curve"] set];
      [curve stroke];
    }
    
    [curve removeAllPoints];
    [displacement removeAllPoints];
  }

  [NSGraphicsContext restoreGraphicsState];
}


- (void)viewWillStartLiveResize
{
    if (approximateOnLiveResize)
        drawingResolution = resolution * 9;
}

- (void)viewDidEndLiveResize
{
    drawingResolution = resolution;
    [self setNeedsDisplay:YES];
}


//*********Customization Methods********************
- (void)setRes:(float)inResolution
{
    resolution = inResolution;
    [self setNeedsDisplay:YES];
}

- (void)setShowCurve:(BOOL)state
{
    showCurve = state;
    [self setNeedsDisplay:YES];
}

- (void)setShowFill:(BOOL)state
{
    showFill = state;
    [self setNeedsDisplay:YES];
}

- (NSColor *)curveColor
{
    return [graphColors colorWithKey:@"curve"];
}

- (void)setCurveColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"curve"];
    [self setNeedsDisplay:YES];
}

- (NSColor *)fillColor
{
    return [graphColors colorWithKey:@"fill"];
}

- (void)setFillColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"fill"];
    [self setNeedsDisplay:YES];
}


@end
