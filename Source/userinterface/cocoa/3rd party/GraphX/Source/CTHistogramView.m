//
//  CTHistogramView.m
//
//  Created by Chad Weider on Fri May 28 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//



#import "CTHistogramView.h"

@implementation CTHistogramView

@synthesize bucketWidth;

@synthesize showBorder;
@synthesize showFill;

- (id)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect]) != nil)
  {
    //Set Default Bucket Width
    bucketWidth = 1;
    
    //Set Default Colors
    [graphColors setColor:[ NSColor blackColor ] forKey:@"border"];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"fill"];
      
    //Set Flags
    showBorder = YES;
    showFill   = YES;
    
    //Default SuperClass Settings
    [super setXMin:0]; [super setXMax:10];
    [super setYMin:0]; [super setYMax:10];
    [super setShowXGrid:NO];
    
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

- (void)drawGraph:(NSRect)rect
{
  if (!dataSource)
    return;

  const float maxXBounds = NSMaxX(rect);  // bounds of graph - stored as constants
  const float minXBounds = NSMinX(rect);  // for preformance reasons(used often)
  const float maxYBounds = NSMaxY(rect);
  const float minYBounds = NSMinY(rect);
  
  const double xratio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ÆData/ÆCoordinate -> dg/dx
  const double yratio = (yMax - yMin)/(maxYBounds - minYBounds); //ratio ÆData/ÆCoordinate -> dh/dy
  
  const float yorigin = (0 - yMin)/(yratio) + minYBounds; // y component of the origin
  
  // Create Boxes for Histogram
  // start by finding the first bucket that needs displaying
  float lowerBound = 0 - floor((0 - xMin) / bucketWidth) * xScale;
  float upperLimit = lowerBound + bucketWidth;
  
  float x = (lowerBound - xMin)/(xratio) + minXBounds;
  float y = yorigin;
  
  float x_next = x + (bucketWidth)/(xratio);
  float y_next;
  
  [displacement moveToPoint:NSMakePoint(x,y)];
  
  while (lowerBound <= xMax)   //Draw bars until no longer in Graph range
  {
    //get frequency from DataSource
    float frequency = [dataSource frequencyForBucketWithLowerBound:lowerBound andUpperLimit:upperLimit];
    
    //Calulate values in terms of view
    y_next = (frequency  - yMin)/(yratio) + minYBounds;
    
    [displacement lineToPoint:NSMakePoint(x     , y_next)];
    [displacement lineToPoint:NSMakePoint(x_next, y_next)];
    
    [border moveToPoint:NSMakePoint(x , (y < y_next) ? y : y_next)];
    [border lineToPoint:NSMakePoint(x , yorigin)];
    
    y = y_next;
    x = x_next;
    x_next += (bucketWidth)/(xratio); 
    
    lowerBound  = upperLimit;
    upperLimit += bucketWidth;
  }
  
  [displacement lineToPoint:NSMakePoint(x , yorigin)];
  
  if (showFill)
  {
    [[graphColors colorWithKey:@"fill"] set];
    [displacement fill];
  }

  if (showBorder)
  {
    [[graphColors colorWithKey:@"border"] set];
    [border appendBezierPath:displacement];
    [border stroke];
  }
  
  [border removeAllPoints];
  [displacement removeAllPoints];
}


//*********Customization Methods********************
- (void)setBucketWidth:(float)width;
{
    bucketWidth = width;
    [self setNeedsDisplay:YES];
}

- (void)setShowBorder:(BOOL)state
{
    showBorder = state;
    [self setNeedsDisplay:YES];
}

- (void)setShowFill:(BOOL)state
{
    showFill = state;
    [self setNeedsDisplay:YES];
}

- (NSColor *)borderColor
{
    return [graphColors colorWithKey:@"border"];
}

- (void)setBorderColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"border"];
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
