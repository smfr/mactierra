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
    
    curvePaths        = [[NSMutableArray alloc] init];
    displacementPaths = [[NSMutableArray alloc] init];
  }
  
  return self;
}

- (void)dealloc
{
  [dataSource release];

  [curvePaths release];
  [displacementPaths release];
  
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
    [curvePaths removeAllObjects];
    [displacementPaths removeAllObjects];

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

    NSPoint tmp = NSMakePoint(1,2);

    NSInteger curSeries, numSeries = [dataSource numberOfSeries];
    for (curSeries = 0; curSeries < numSeries; ++curSeries)
    {
        NSPoint *pointPointer = &tmp;

        NSBezierPath*   curve = [NSBezierPath bezierPath];
        [curve setLineWidth:curveLineWidth];
        [curve setLineJoinStyle:NSLineJoinStyleRound];
        [curve setLineCapStyle :NSLineCapStyleRound ];
    
        NSBezierPath*   displacement = [NSBezierPath bezierPath];

        // the sample data point's coordinates
        unsigned index = 0;

        float g = xMin;
        float h = NAN; 

        float g_next = 0;
        float h_next = 0;

        float xMinRatio = xMin / xratio;
        float hMinRatio = yMin / yRatio;

        float x = 0;
        float y = 0;

        [dataSource getPoint:&pointPointer atIndex:index inSeries:curSeries];
      
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
                [dataSource getPoint:&pointPointer atIndex:(++index) inSeries:curSeries];
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
                    [dataSource getPoint:&pointPointer atIndex:(++index) inSeries:curSeries];
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
                    [dataSource getPoint:&pointPointer atIndex:(++index) inSeries:curSeries];
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
        
        [curvePaths addObject:curve];
        [displacementPaths addObject:displacement];
    }
}

- (void)drawGraph:(NSRect)rect
{
    if (showFill)
    {
        [[graphColors colorWithKey:@"fill"] set];
        [displacementPaths makeObjectsPerformSelector:@selector(fill)];
    }
    
    if (showCurve)
    {
        NSInteger i, numCurves = [curvePaths count];
        for (i = 0; i < numCurves; ++i)
        {
            [[self curveColorForSeries:i] set];
            [[curvePaths objectAtIndex:i] stroke];
        }
    }
}

- (NSColor *)curveColor
{
    return [graphColors colorWithKey:@"curve"];
}

- (void)setCurveColor:(NSColor *)color
{
    [self willChangeValueForKey:@"curveColor"];
    [graphColors setColor:color forKey:@"curve"];
    [self didChangeValueForKey:@"curveColor"];
}

- (NSColor *)fillColor
{
    return [graphColors colorWithKey:@"fill"];
}

- (void)setFillColor:(NSColor *)color
{
    [self willChangeValueForKey:@"fillColor"];
    [graphColors setColor:color forKey:@"fill"];
    [self didChangeValueForKey:@"fillColor"];
}

- (void)setCurveColor:(NSColor*)color forSeries:(NSInteger)series
{
    if (series == 0)
    {
        [self setCurveColor:color];
        return;
    }
    NSString* colorKey = [NSString stringWithFormat:@"curve_%ld", (long)series];
    [graphColors setColor:color forKey:colorKey];
}

- (NSColor*)curveColorForSeries:(NSInteger)series
{
    if (series == 0)
        return [self curveColor];

    NSString* colorKey = [NSString stringWithFormat:@"curve_%ld", (long)series];
    return [graphColors colorWithKey:colorKey];
}


@end
