//
//  CTHistogramView.m
//
//  Created by Chad Weider on Fri May 28 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//



#import "CTHistogramView.h"

@implementation CTHistogramView

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
    drawBorderFlag = YES;
    drawFillFlag   = YES;
    
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

  const float xMax = NSMaxX(rect);  //bounds of graph - stored as constants
  const float xMin = NSMinX(rect);  // for preformance reasons(used often)
  const float yMax = NSMaxY(rect);
  const float yMin = NSMinY(rect);
  
  const double xratio = (gMax - gMin)/(xMax - xMin); //ratio ÆData/ÆCoordinate -> dg/dx
  const double yratio = (hMax - hMin)/(yMax - yMin); //ratio ÆData/ÆCoordinate -> dh/dy
  
  const float yorigin = (0 - hMin)/(yratio) + yMin; //y component of the origin
  
    
  //Create Boxes for Histogram
  //start by finding the first bucket that needs displaying
  float lowerBound = 0 - floor((0-gMin)/bucketWidth)*gScale;
  float upperLimit = lowerBound + bucketWidth;
  float frequency;    //number of observations in range
  
  float x = (lowerBound - gMin)/(xratio) + xMin;
  float y = yorigin;
  
  float x_next = x + (bucketWidth)/(xratio);
  float y_next;
  
  
  [displacement moveToPoint:NSMakePoint(x,y)];
  
  while(lowerBound <= gMax)   //Draw bars until no longer in Graph range
  {
    //get frequency from DataSource
    frequency = [dataSource frequencyForBucketWithLowerBound:lowerBound andUpperLimit:upperLimit];
    
    //Calulate values in terms of view
    y_next = (frequency  - hMin)/(yratio) + yMin;
    
    
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
  
  if (drawFillFlag == YES )
  {
    [[graphColors colorWithKey:@"fill"] set];
    [displacement fill];
  }

  if (drawBorderFlag == YES )
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
  drawBorderFlag = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowFill:(BOOL)state
{
  drawFillFlag = state;
  [self setNeedsDisplay:YES];
}

- (void)setBorderColor:(NSColor *)color
{
  [graphColors setColor:color forKey:@"border"];
  [self setNeedsDisplay:YES];
}

- (void)setFillColor:(NSColor *)color
{
  [graphColors setColor:color forKey:@"fill"];
  [self setNeedsDisplay:YES];
}






//************State Methods****************
- (float)bucketWidth
{
  return bucketWidth;
}


- (BOOL)showBorder
{
  return drawBorderFlag;
}

- (BOOL)showFill
{
  return drawFillFlag;
}


- (NSColor *)borderColor
{
  return [graphColors colorWithKey:@"border"];
}

- (NSColor *)fillColor
{
  return [graphColors colorWithKey:@"fill"];
}

@end
