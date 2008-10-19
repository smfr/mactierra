//
//  CTScatterPlotView.m
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//



#import "CTScatterPlotView.h"

@implementation CTScatterPlotView

@synthesize showCurve;
@synthesize showFill;

+ (NSSet *)keyPathsForValuesAffectingNeedsRecomputation
{
    return [[super keyPathsForValuesAffectingNeedsRecomputation] setByAddingObjectsFromSet:
                          [NSSet setWithObjects:@"showCurve",
                                                @"showFill",
                                                @"curveColor",
                                                @"fillColor",
                                                nil]];
}

- (id)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect]) != nil)
  {
    //Set Default Colors
    [graphColors setColor:[ NSColor blackColor ] forKey:@"curve"];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"fill"];
    
    //Set Flags
    showCurve  = YES;
    showFill   = YES;
    
    //Default SuperClass Settings
    [super setXMin:0]; [super setXMax:10];
    [super setYMin:0]; [super setYMax:10];
    [super setShowXGrid:NO];
    
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
  [dataSource release];

  [curve release];
  [displacement release];
  
  [super dealloc];
}

- (void)setDataSource:(id)inDataSource
{
    if (inDataSource != dataSource)
    {
        [dataSource release];
        dataSource = [inDataSource retain];
    }
}

- (void)setDelegate:(id)inDelegate
{
    delegate = inDelegate;
}

- (void)recomputeGraph:(NSRect)rect
{
    [curve removeAllPoints];
    [displacement removeAllPoints];

    if (!dataSource)
        return;

    const float maxXBounds = NSMaxX(rect);  //bounds of graph - stored as constants
    const float minXBounds = NSMinX(rect);  // for preformance reasons (used often)
    const float maxYBounds = NSMaxY(rect);
    const float minYBounds = NSMinY(rect);

    const float xratio = (xMax - xMin) / (maxXBounds - minXBounds); //ratio ÆData/ÆCoordinate -> dg/dx
    const float yRatio = (yMax - yMin) / (maxYBounds - minYBounds); //ratio ÆData/ÆCoordinate -> dh/dy

    //const float xOrigin = (0 - xMin)/(xratio) + minXBounds; //x component of the origin
    const float yOrigin = (0 - yMin) / (yRatio) + minYBounds; //y component of the origin

    //Create Curve Path then Draw Curve and Fill Area underneath

    //will now start sampling graph values to form graph points, then converting them to pixel points,
    //and finally feeding them into the curve
    //
    //Sampling will begin at xMin and finish off at xMax
    //  any points that return null will be ignored

    //the sample data point's coordinates
    unsigned index = 0;


    NSPoint tmp = NSMakePoint(1,2);

    NSPoint *pointPointer = &tmp;

    float g = xMin;
    float h = NAN; 

    float g_next;
    float h_next;

    float xMinRatio = xMin / xratio;
    float hMinRatio = yMin / yRatio;

    float x;
    float y;

    [dataSource getPoint:&pointPointer atIndex:index];
  
    while (g < xMax &&  pointPointer != nil)
    {
        while ((g < xMax &&  pointPointer != nil) && isnan(h))
        {
            g_next = pointPointer->x;
            h_next = pointPointer->y;

            if (isnan(h_next))
            {
            }
            else
            {
                x = (g_next)/(xratio) - xMinRatio + minXBounds;

                if (isfinite(h_next))              //move to the right to the point
                y = (h_next)/(yRatio) - hMinRatio + minYBounds;
                else if (signbit(h_next))            //move to top of screen
                y = maxYBounds + curveLineWidth;
                else                      //move to bottom of screen
                y = minYBounds - curveLineWidth;

                [curve moveToPoint:NSMakePoint(x, y)];
            }

            g = g_next;
            h = h_next;
            [dataSource getPoint:&pointPointer atIndex:(++index)];
        }

        //Make sure we aren't ending with NaN
        if (g >= xMax && isnan(h))
            break;

        float firstPoint = g/(xratio) - xMinRatio + minXBounds;

        while (!isnan(h))
        {
            while((g < xMax &&  pointPointer != nil) && isfinite(h))
            {
                g_next = pointPointer->x;
                h_next = pointPointer->y;

                if (isnan(h_next))
                {
                    break;
                }
                else    // Next point is valid - draw a line to it
                {
                    if (isfinite(h_next))              //line to the right to the point
                    {
                        x = (g_next)/(xratio) - xMinRatio + minXBounds;
                        y = (h_next)/(yRatio) - hMinRatio + minYBounds;
                    }
                    else if (signbit(h_next))            //line to top of screen
                        y = maxYBounds + curveLineWidth;
                    else                      //line to bottom of screen
                        y = minYBounds - curveLineWidth;

                    [curve lineToPoint:NSMakePoint(x,y)];
                }

                g = g_next;
                h = h_next;
                [dataSource getPoint:&pointPointer atIndex:(++index)];
            }

            while(!isfinite(h) && !isnan(h) && (g < xMax &&  pointPointer != nil))
            {
                g_next = pointPointer->x;
                h_next = pointPointer->y;

                if (isnan(h_next))
                {
                    break;
                }
                else if (!isnan(h_next)) // Next point is valid - draw a line to it
                {
                    x = (g_next)/(xratio) - xMinRatio + minXBounds;
                    y = signbit(h) ? maxYBounds + curveLineWidth : minYBounds - curveLineWidth;

                    [curve lineToPoint:NSMakePoint(x,y)];

                    //Next point is valid - draw a line to it
                    x = (g_next)/(xratio) - xMinRatio + minXBounds;

                    if (isfinite(h_next))              //move to the right to the point
                        y = (h_next)/(yRatio) - hMinRatio + minYBounds;
                    else if (signbit(h_next))            //move to top of screen
                        y = maxYBounds + curveLineWidth;
                    else                      //move to bottom of screen
                        y = minYBounds - curveLineWidth;

                    [curve lineToPoint:NSMakePoint(x,y)];
                }

                g = g_next;
                h = h_next;
                [dataSource getPoint:&pointPointer atIndex:(++index)];
            }

            if (isnan(h_next) || (g >= xMax || pointPointer == nil))
                break;
        }

        //Set points up for next segment
        g = g_next;
        h = h_next;

        if (showFill)
        {
            //Create new path that will be filled
            [displacement appendBezierPath:curve];

            //move curve to x axis, then go across it to the begining of the segment
            [displacement lineToPoint:NSMakePoint(x, yOrigin)];
            [displacement lineToPoint:NSMakePoint(firstPoint, yOrigin)];
        }
    }
}

- (void)drawGraph:(NSRect)rect
{
    if (showFill)
    {
        [[graphColors colorWithKey:@"fill"] set];
        [displacement fill];
    }
    
    if (showCurve)
    {
        [[graphColors colorWithKey:@"curve"] set];
        [curve stroke];
    }
}

- (NSColor *)curveColor
{
    return [graphColors colorWithKey:@"curve"];
}

- (void)setCurveColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"curve"];
}

- (NSColor *)fillColor
{
    return [graphColors colorWithKey:@"fill"];
}

- (void)setFillColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"fill"];
}


@end
