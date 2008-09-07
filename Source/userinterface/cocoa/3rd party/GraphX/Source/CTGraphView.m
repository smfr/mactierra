//
//  CTGraphView.m
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent Solution. All rights reserved.
//



#import "CTGraphView.h"


@interface CTGraphView(Private)

- (float)titleHeight ;   //Gives amount of space used by Title(at the top of the graph) - if drawTitleFlag is NO then it will give a height of 0
- (float)xLabelHeight;   //Gives amount of space used by XAxis Label size depends on if flag is set
- (float)yLabelWidth ;   //Gives amount of space used by YAxis Label size depends on if flag is set

- (void)drawTitle :(NSRect)rect;    //Will draw title at the top of the Graph
- (void)drawXLabel:(NSRect)rect;    //Will draw X Axis Label - if Flag is set
- (void)drawYLabel:(NSRect)rect;    //Will draw Y Axis Label - if Flag is set

- (void)drawBackground:(NSRect)rect;//Fills the Graph Region

- (void)drawXGrid:(NSRect)rect;     //Will draw Vertical Gridlines
- (void)drawYGrid:(NSRect)rect;     //Will draw Horizontal Gridlines

- (void)drawXAxis:(NSRect)rect;     //Will draw X Axis line, tick marks, numbers
- (void)drawYAxis:(NSRect)rect;     //Will draw Y Axis line, tick marks, numbers

@end

#pragma mark -

@implementation CTGraphView

@synthesize xMin;
@synthesize xMax;
@synthesize xScale;
@synthesize xMinorLineCount;

@synthesize yMin;
@synthesize yMax;
@synthesize yScale;
@synthesize yMinorLineCount;

@synthesize showTitle;
@synthesize showBackground;

@synthesize showXLabel;
@synthesize showXAxis;
@synthesize showXValues;
@synthesize showXGrid;
@synthesize showXTickMarks;

@synthesize showYLabel;
@synthesize showYAxis;
@synthesize showYValues;
@synthesize showYGrid;
@synthesize showYTickMarks;

@synthesize title;
@synthesize xLabel;
@synthesize yLabel;

+ (NSDictionary*)axisLabelAttributes
{
    static NSDictionary* sAxisLabelAttributes = nil;

    if (!sAxisLabelAttributes)
    {
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSCenterTextAlignment];

        sAxisLabelAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont paletteFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
                                               [NSColor blackColor], NSForegroundColorAttributeName,
                                                             pStyle, NSParagraphStyleAttributeName,
                                                                    nil] retain];
        [pStyle release];
    }
    return sAxisLabelAttributes;
}

+ (NSDictionary*)titleAttributes
{
    static NSDictionary* sAxisLabelAttributes = nil;

    if (!sAxisLabelAttributes)
    {
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSCenterTextAlignment];

        sAxisLabelAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
              [NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName,
                                               [NSColor blackColor], NSForegroundColorAttributeName,
                                                             pStyle, NSParagraphStyleAttributeName,
                                                                    nil] retain];
        [pStyle release];
    }
    return sAxisLabelAttributes;
}

- (id)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect]) != nil)
  {
    // Set Default Graph Bounds
    xMin = -10;   xMax = 10;  xScale = 1;
    yMin = -10;   yMax = 10;  yScale = 1;

    // Set Default Colors
    graphColors = [[NSColorList alloc] initWithName:@"Graph Colors"];
    [graphColors setColor:[ NSColor whiteColor ] forKey:@"background"];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.6)] forKey:@"xMajor"  ];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.6)] forKey:@"yMajor"  ];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"xMinor"  ];
    [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"yMinor"  ];
    [graphColors setColor:[ NSColor blackColor ] forKey:@"xaxis"     ];
    [graphColors setColor:[ NSColor blackColor ] forKey:@"yaxis"     ];
    
    // Set Default Strings
    xLabel = [[NSAttributedString alloc] initWithString:@"X Axis Label" attributes:[CTGraphView axisLabelAttributes]];
    yLabel = [[NSAttributedString alloc] initWithString:@"Y Axis Label" attributes:[CTGraphView axisLabelAttributes]];

    title  = [[NSAttributedString alloc] initWithString:@"Title Text"   attributes:[CTGraphView titleAttributes]];
    
    //Set Flags
    showTitle  = YES;
    showBackground = YES;

    showXAxis  = YES;
    showXValues = YES;
    showXGrid = YES;
    showXTickMarks = YES;

    showYAxis  = YES;
    showYValues = YES;
    showYGrid = YES;
    showYTickMarks = YES;

    // Set Drawing Constants
    labelPadding     = 2;
    titlePadding     = 4;
    
    xMinorLineCount  = 0;
    yMinorLineCount  = 0;
    
    majorLineWidth   = 1;
    minorLineWidth   = 1;
    axisLineWidth    = 1;
    
    lineDashPattern[0]  = 4;  // segment painted with stroke color
    lineDashPattern[1]  = 5;  // segment not painted with a color
  }
  
  return self;
}

- (void)dealloc
{
  [graphColors release];
  self.xLabel = nil;
  self.yLabel = nil;
  self.title = nil;

  [super dealloc];
}

- (float)titleHeight
{
  if (showTitle)
    return [title size].height + titlePadding;

  return 0;
}

- (float)xLabelHeight
{
  if (showXLabel)
    return [xLabel size].height + labelPadding;

  return 0;
}

- (float)yLabelWidth
{
  [yLabel size];
  if (showYLabel)
    return [yLabel size].height + labelPadding;

  return 0;
}

- (void)drawGraph:(NSRect)graphRect
{
    // overridden by subclasses
}

- (void)drawRect:(NSRect)inDirtyRect   //mainly function calls to more complex implementation
{
  NSRect rect = [self bounds];
  //First Draw the Title, X/Y Axis & Labels
  [self drawTitle :rect];
  [self drawXLabel:rect];
  [self drawYLabel:rect];
  
  //Size of X and Y Axis vary (depends on if labels or numbers are drawn) so the Actual Graph's size will vary
  // Adjust for this by subtracting height of Title & XAxis as well as the width of YAxis from View's Rect
  
  float tHeight = [self titleHeight ];   //height of Title
  float xHeight = [self xLabelHeight];   //height of X Axis Label
  float yWidth  = [self yLabelWidth ];   //height of Y Axis Label
  
  NSRect graphRect =  NSMakeRect(NSMinX (rect) + yWidth, NSMinY(rect)   + xHeight           , //Make Adjusted Graph
                 NSWidth(rect) - yWidth, NSHeight(rect) - xHeight - tHeight);
  
  NSRectClip(graphRect); //don't allow drawing outside of graphRect from this point onward
  
  //Draw the Background
  [self drawBackground:(graphRect)];
  
  //Draw the Grid Lines
  [self drawXGrid:graphRect];
  [self drawYGrid:graphRect];
  
  //Draw Curve and Area
  [self drawGraph:graphRect];
  
  //Finish up by drawing the X and Y Axis (dependent on flags)
  [self drawXAxis:graphRect];
  [self drawYAxis:graphRect];
}
  
- (void)drawTitle:(NSRect)rect;
{
  if (showTitle)
    [title drawInRect:NSMakeRect(NSMinX(rect) + [self yLabelWidth], NSMaxY(rect) - [title size].height, NSWidth(rect) - NSMinX(rect) - [self yLabelWidth], [title size].height)];
}

- (void)drawXLabel:(NSRect)rect
{
  if (showXLabel)
    [xLabel drawInRect:NSMakeRect(NSMinX(rect) + [self yLabelWidth], NSMinY(rect), NSWidth(rect) - NSMinX(rect) - [self yLabelWidth], [xLabel size].height)];
}

- (void)drawYLabel:(NSRect)rect
{
    if (!showYLabel)
        return;

    NSAffineTransform *transform = [NSAffineTransform transform];
    NSGraphicsContext *context   = [NSGraphicsContext currentContext];
  
    [transform rotateByDegrees:90.0];
    
    [context saveGraphicsState];
    [transform concat];
  
    [yLabel drawInRect:NSMakeRect( [self xLabelHeight], -[yLabel size].height, NSMaxY(rect) - [self titleHeight] - [self xLabelHeight], [yLabel size].height)];

    [context restoreGraphicsState];
}


- (void)drawBackground:(NSRect)rect
{
  if (showBackground)
  {
    [[graphColors colorWithKey:@"background"] set];
    NSRectFill(rect);
  }
}


- (void)drawXGrid:(NSRect)rect
{
    if (!showXGrid)
        return;

    NSBezierPath *majorGridLines = [[NSBezierPath alloc] init]; //creates series of lines that will be gridlines on x
    NSBezierPath *minorGridLines = [[NSBezierPath alloc] init];
    NSBezierPath *tickMarks      = [[NSBezierPath alloc] init];

    const float maxXBounds = NSMaxX(rect);  //bounds of graph - stored as constants
    const float minXBounds = NSMinX(rect);  // for preformance reasons(used often)
    const float maxYBounds = NSMaxY(rect);
    const float minYBounds = NSMinY(rect);

    const float xratio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ÆData/ÆCoordinate -> dg/dx

    const float xorigin = (0 - xMin)/xratio + minXBounds; //x component of the origin

    const float scaleX = xScale / xratio; //transform scale

    float x;   //view coordinate x

    for (x = xorigin - floor((xorigin - minXBounds + 1) / scaleX) * scaleX; x <= maxXBounds + scaleX; x += scaleX) //Begin 1 scale unit outside of graph
    {                                         //End 1 scale unit outside of graph
      [majorGridLines moveToPoint:NSMakePoint(x, maxYBounds)];
      [majorGridLines lineToPoint:NSMakePoint(x, minYBounds)];
      
      float minor;
      for (minor = 1; minor < xMinorLineCount; minor++)
      {
        [minorGridLines moveToPoint:NSMakePoint(x + minor / xMinorLineCount * scaleX, maxYBounds)];
        [minorGridLines lineToPoint:NSMakePoint(x + minor / xMinorLineCount * scaleX, minYBounds)];
      }
    }

    [[graphColors colorWithKey:@"xMajor"] set];       //set color for grindlines
    [majorGridLines setLineWidth:majorLineWidth];     //make line width consistent with env. variable
    [majorGridLines stroke];

    [[graphColors colorWithKey:@"xMinor"] set];       //set color for grindlines
    [minorGridLines setLineWidth:minorLineWidth];     //make line width consistent with env. variable
    [minorGridLines stroke];

    [majorGridLines release];
    [minorGridLines release];
    [tickMarks release];
}

- (void)drawYGrid:(NSRect)rect
{
    if (!showYGrid)
        return;

    NSBezierPath *majorGridLines = [[NSBezierPath alloc] init]; //creates series of lines that will be gridlines on y
    NSBezierPath *minorGridLines = [[NSBezierPath alloc] init];
    
    const float maxXBounds = NSMaxX(rect);  //bounds of graph - stored as constants
    const float minXBounds = NSMinX(rect);  // for preformance reasons(used often)
    const float maxYBounds = NSMaxY(rect);
    const float minYBounds = NSMinY(rect);

    const float yratio = (yMax - yMin)/(maxYBounds - minYBounds); //ratio ÆData/ÆCoordinate -> dh/dy

    const float yorigin = (0 - yMin)/(yratio) + minYBounds; //y component of the origin

    const float scaleY = yScale / yratio; //transform scale
    
    float  y;   //view coordinate y
    for (y = yorigin - floor((yorigin - minYBounds) / scaleY + 1) * scaleY; y <= maxYBounds + scaleY; y += scaleY) //Begin 1 scale unit outside of graph
    {                                         //End 1 scale unit outside of graph
      [majorGridLines moveToPoint:NSMakePoint(maxXBounds,y)];
      [majorGridLines lineToPoint:NSMakePoint(minXBounds,y)];
      
      float minor;
      for (minor = 1; minor < yMinorLineCount; minor++)
      {
        [minorGridLines moveToPoint:NSMakePoint(maxXBounds, y + minor / yMinorLineCount * scaleY)];
        [minorGridLines lineToPoint:NSMakePoint(minXBounds, y + minor / yMinorLineCount * scaleY)];
      }
    }
    
    
    [[graphColors colorWithKey:@"yMajor"] set];       //set color for grindlines
    [majorGridLines setLineWidth:majorLineWidth];     //make line width consistent with env. variable
    [majorGridLines stroke];
    
    [[graphColors colorWithKey:@"yMinor"] set];       //set color for grindlines
    [minorGridLines setLineWidth:minorLineWidth];     //make line width consistent with env. variable
    [minorGridLines stroke];
    
    [majorGridLines release];
    [minorGridLines release];
}

- (void)drawXAxis:(NSRect)rect
{
    if (!showXAxis)
        return;

    //Create Axis Path & Format it
    NSBezierPath *axis      = [[NSBezierPath alloc] init];
    NSBezierPath *tickMarks = [[NSBezierPath alloc] init];
    [[graphColors colorWithKey:@"xaxis"] set];
    [axis      setLineWidth:axisLineWidth];
    [tickMarks setLineWidth:axisLineWidth];
    
    //find y coordinate where h = 0 - use abbreviated transformation
    const float maxXBounds = NSMaxX(rect);
    const float minXBounds = NSMinX(rect);
    const float maxYBounds = NSMaxY(rect);
    const float minYBounds = NSMinY(rect);
    
    const float xratio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ÆData/ÆCoordinate -> dg/dx
    
    const float xorigin = (0 - xMin)/xratio + minXBounds; //x component of the origin
    
    const float scaleX = xScale / xratio; //transform scale
      
    float y = (0 - yMin)/((yMax - yMin)/(maxYBounds - minYBounds)) + minYBounds;
    
    //draw axis
    if (y > maxYBounds)  //if axis is higher than graph draw dashed axis at top
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
      
      //draw line at y = maxYBounds
      y = maxYBounds;
    }
    else if (y < minYBounds) //if axis is lower than graph draw dashed axis at bottom
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
          
      //draw line at y = yMain
      y = minYBounds;
    }
    
    [axis moveToPoint:NSMakePoint(minXBounds,y)];
    [axis lineToPoint:NSMakePoint(maxXBounds,y)];
    
    if (showXTickMarks)
    {
      float x;
      for (x = xorigin - floor((xorigin - minXBounds + 1) / scaleX) * scaleX; x <= maxXBounds + scaleX; x += scaleX) //Begin 1 scale unit outside of graph
      {                                         //End 1 scale unit outside of graph
        [tickMarks moveToPoint:NSMakePoint(x, y - 3)];
        [tickMarks lineToPoint:NSMakePoint(x, y + 3)];
      }
    }
    
    [axis      stroke];
    [tickMarks stroke];
      
    [axis      release];
    [tickMarks release];
}


- (void)drawYAxis:(NSRect)rect
{
    if (!showYAxis)
        return;

    //Create Axis Path & Format it
    NSBezierPath *axis      = [[NSBezierPath alloc] init];
    NSBezierPath *tickMarks = [[NSBezierPath alloc] init];
    [[graphColors colorWithKey:@"yaxis"] set];   
    [axis      setLineWidth:axisLineWidth];
    [tickMarks setLineWidth:axisLineWidth];
    
    //find y coordinate where h = 0 - use abbreviated transformation
    const float maxXBounds = NSMaxX(rect);
    const float minXBounds = NSMinX(rect);
    const float maxYBounds = NSMaxY(rect);
    const float minYBounds = NSMinY(rect);
    
    const float yratio = (yMax - yMin)/(maxYBounds - minYBounds); //ratio ÆData/ÆCoordinate -> dh/dy

    const float yorigin = (0 - yMin)/(yratio) + minYBounds; //y component of the origin

    const float scaleY = yScale / yratio; //transform scale
    
    float x = (0 - minXBounds)/((xMax - minXBounds)/(maxXBounds - minXBounds)) + minXBounds;
    
    //draw axis
    if (x > maxXBounds)  //if axis is higher than graph draw dashed axis at top
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
      
      //draw line at x = maxXBounds
      x = maxXBounds;
    }
    else if (x < minXBounds) //if axis is lower than graph draw dashed axis at bottom
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
          
      //draw line at x = minXBounds
      x = minXBounds;
    }
    
    [axis moveToPoint:NSMakePoint(x,minYBounds)];
    [axis lineToPoint:NSMakePoint(x,maxYBounds)];
    
    if (showYTickMarks)
    {
      float y;
      for (y = yorigin - floor((yorigin - minYBounds) / scaleY + 1) * scaleY; y <= maxYBounds + scaleY; y += scaleY) //Begin 1 scale unit outside of graph
      {                                         //End 1 scale unit outside of graph
        [tickMarks moveToPoint:NSMakePoint(x - 3, y)];
        [tickMarks lineToPoint:NSMakePoint(x + 3, y)];
      }
    }
      
    [axis      stroke];
    [tickMarks stroke];
      
    [axis      release];
    [tickMarks release];
}


- (NSData *)graphImage
{
  return [self dataWithPDFInsideRect:[self bounds]];
}







//*********Customization Methods********************
- (void)setXMin:(float)bound
{
  if (bound >= xMax)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid lower bound" userInfo:nil] raise];
  else
    xMin = bound;
  [self setNeedsDisplay:YES];
}

- (void)setXMax:(float)bound
{
  if (bound <= xMin)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid upper bound" userInfo:nil] raise];
  else
    xMax = bound;
  [self setNeedsDisplay:YES];
}

- (void)setXScale:(float)scale
{
  xScale = scale;
  [self setNeedsDisplay:YES];
}

- (void)setXMinorLineCount:(unsigned)count
{
  xMinorLineCount = count;
  [self setNeedsDisplay:YES];
}

- (void)setYMin:(float)bound
{
  if (bound >= yMax)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid lower bound" userInfo:nil] raise];
  else
    yMin = bound;
  [self setNeedsDisplay:YES];
}

- (void)setYMax:(float)bound
{
  if (bound <= yMin)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid upper bound" userInfo:nil] raise];
  else
    yMax = bound;
  [self setNeedsDisplay:YES];
}

- (void)setYScale:(float)scale
{
  yScale = scale;
  [self setNeedsDisplay:YES];
}

- (void)setYMinorLineCount:(unsigned)count
{
  yMinorLineCount = count;
  [self setNeedsDisplay:YES];
}

- (void)setShowTitle:(BOOL)state
{
  showTitle  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowXLabel:(BOOL)state
{
  showXLabel = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowXAxis :(BOOL)state
{
  showXAxis  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowXValues :(BOOL)state
{
  showXValues  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowXGrid :(BOOL)state
{
  showXGrid  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowXTickMarks:(BOOL)state
{
  showXTickMarks = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowYLabel:(BOOL)state
{
  showYLabel = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowYAxis:(BOOL)state
{
  showYAxis  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowYValues:(BOOL)state
{
  showYValues  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowYGrid:(BOOL)state
{
  showYGrid  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowYTickMarks:(BOOL)state
{
  showYTickMarks = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowBackground:(BOOL)state
{
  showBackground = state;
  [self setNeedsDisplay:YES];
}


- (NSColor *)xAxisColor
{
    return [graphColors colorWithKey:@"xaxis"];
}

- (void)setXAxisColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"xaxis"];
    [self setNeedsDisplay:YES];
}

- (NSColor *)xGridColor
{
    return [graphColors colorWithKey:@"xMajor"];
}

- (void)setXGridColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"xMajor"];
    [self setNeedsDisplay:YES];
}

- (NSColor *)yAxisColor
{
    return [graphColors colorWithKey:@"yaxis"];
}

- (void)setYAxisColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"yaxis"];
    [self setNeedsDisplay:YES];
}

- (NSColor *)yGridColor
{
    return [graphColors colorWithKey:@"yMajor"];
}

- (void)setYGridColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"yMajor"];
    [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor
{
    return [graphColors colorWithKey:@"background"];
}

- (void)setBackgroundColor:(NSColor *)color
{
    [graphColors setColor:color forKey:@"background"];
    [self setNeedsDisplay:YES];
}


- (void)setTitle:(NSAttributedString *)string
{
    if (string != title)
    {
        [title release];
        title = [string retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setXLabel:(NSAttributedString *)string
{
    if (string != xLabel)
    {
        [xLabel release];
        xLabel = [string retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setYLabel:(NSAttributedString *)string
{
    if (string != yLabel)
    {
        [yLabel release];
        yLabel = [string retain];
        [self setNeedsDisplay:YES];
    }
}

@end
