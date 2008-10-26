//
//  CTHistogramView.m
//
//  Created by Chad Weider on Fri May 28 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//



#import "CTHistogramView.h"

@implementation CTHistogramView

@synthesize numberOfBuckets;

@synthesize showBorder;
@synthesize showFill;

+ (NSSet *)keyPathsForValuesAffectingNeedsRecomputation
{
    return [[super keyPathsForValuesAffectingNeedsRecomputation] setByAddingObjectsFromSet:
                          [NSSet setWithObjects:@"numberOfBuckets",
                                                @"showBorder",
                                                @"showFill",
                                                @"borderColor",
                                                @"fillColor",
                                                nil]];
}

- (id)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect]) != nil)
  {
    self.numberOfBuckets = 10;
    
    //Set Default Colors
    [graphColors setColor:[ NSColor blackColor ] forKey:@"border"];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"fill"];
      
    //Set Flags
    self.showBorder = YES;
    self.showFill   = YES;
    
    //Default SuperClass Settings
    self.yMin = 0;
    self.yMax = 10;
    self.showXGrid = NO;
    
    //Set Drawing Constants
    borderLineWidth =  1;
    
    border       = [[NSBezierPath alloc] init];
    displacement = [[NSBezierPath alloc] init];
    
    [border setLineWidth:borderLineWidth];
    [border setLineJoinStyle:NSRoundLineJoinStyle];
    [border setLineCapStyle :NSRoundLineCapStyle ];
  }
  
  return self;
}

- (void)dealloc
{
    [dataSource release];
    [border release];
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

- (void)drawXValues:(NSRect)rect
{
    // override to do nothing. we draw our own labels
}

- (void)drawLabel:(NSString*)inLabel forBucket:(NSUInteger)inBucket inRect:(NSRect)inGraphRect
{
    const float minXBounds = NSMinX(inGraphRect);  // for preformance reasons(used often)
    const float maxXBounds = NSMaxX(inGraphRect);  // bounds of graph - stored as constants

    const float minYBounds = NSMinY(inGraphRect);

    float labelWidth = (maxXBounds - minXBounds) / numberOfBuckets;
    float labelXPos = minXBounds + inBucket * labelWidth;
    
    float valueHeight = [self xValueHeight];
    float labelBottom = minYBounds - valueHeight - self.xAxisLabelOffset - (externalTickMarks ? self.tickMarkLength : 0.0f);
    
    NSMutableAttributedString* labelString = [[[NSMutableAttributedString alloc] initWithString:inLabel
                                                                                     attributes:xAxisValueTextAttributes] autorelease];
    NSRect textRect = NSMakeRect(labelXPos, labelBottom, labelWidth, valueHeight);

    [labelString drawInRect:textRect];
}

- (void)recomputeGraph:(NSRect)rect
{
    [border removeAllPoints];
    [displacement removeAllPoints];

    if (!dataSource)
        return;

    const float minXBounds = NSMinX(rect);  // for preformance reasons(used often)
    const float maxXBounds = NSMaxX(rect);  // bounds of graph - stored as constants

    const float minYBounds = NSMinY(rect);
    const float maxYBounds = NSMaxY(rect);

    const double xRatio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ÆData/ÆCoordinate -> dg/dx
    const double yRatio = (yMax - yMin)/(maxYBounds - minYBounds); //ratio ÆData/ÆCoordinate -> dh/dy

    const float yOrigin = (0 - yMin)/(yRatio) + minYBounds; // y component of the origin

    const float bucketPixelWidth = (maxXBounds - minXBounds) / numberOfBuckets;
    
    NSInteger numSeries = [dataSource numberOfSeries];
    // FIXME: need to correctly draw more than one series of columns
    NSInteger curSeries;
    for (curSeries = 0; curSeries < numSeries; ++curSeries)
    {
        // Create Boxes for Histogram
        float x = minXBounds;
        float y = yOrigin;

        float x_next = x + (1)/(xRatio);
        float y_next;

        [displacement moveToPoint:NSMakePoint(x,y)];

        NSUInteger i;
        for (i = 0; i < numberOfBuckets; ++i)
        {
            NSString* label = nil;
            float frequency = [dataSource frequencyForBucket:i label:&label inSeries:curSeries];
        
            y_next = minYBounds + (frequency  - yMin)/(yRatio);

            [displacement lineToPoint:NSMakePoint(x     , y_next)];
            [displacement lineToPoint:NSMakePoint(x_next, y_next)];

            [border moveToPoint:NSMakePoint(x , (y < y_next) ? y : y_next)];
            [border lineToPoint:NSMakePoint(x , yOrigin)];

            // FIXME: we should not be drawing labels here
            if (showXValues && label)
                [self drawLabel:label forBucket:i inRect:rect];

            y = y_next;
            x = x_next;
            x_next += bucketPixelWidth;
        }

        [displacement lineToPoint:NSMakePoint(x , yOrigin)];
    }
}

- (void)drawGraph:(NSRect)rect
{
    if (showFill)
    {
        [[graphColors colorWithKey:@"fill"] set];
        [displacement fill];
    }

    // Draw labels here
    
    
    if (showBorder)
    {
        [[graphColors colorWithKey:@"border"] set];
        [border appendBezierPath:displacement];
        [border stroke];
    }
}

- (void)setNumberOfBuckets:(NSUInteger)inNumBuckets;
{
    numberOfBuckets = inNumBuckets;
    self.xMin = 0;
    self.xMax = inNumBuckets;
    [self setNeedsDisplay:YES];
}

- (NSColor *)borderColor
{
    return [graphColors colorWithKey:@"border"];
}

- (void)setBorderColor:(NSColor *)color
{
    [self willChangeValueForKey:@"borderColor"];
    [graphColors setColor:color forKey:@"border"];
    [self didChangeValueForKey:@"borderColor"];
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


@end
