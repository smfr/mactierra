//
//  CTGraphView.m
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent Solution. All rights reserved.
//



#import "CTGraphView.h"

@implementation CTGraphView

- (id)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect]) != nil)
  {
    //Set Default Graph Bounds              //**IMPORTANT NAMING CONVENTION**/
    gMin = -10;   gMax = 10;  gScale = 1;       //Data Point = (g,h)  variables prefixed by g/h refer to data values
    hMin = -10;   hMax = 10;  hScale = 1;       //PixelPoint = (x,y)  variables prefixed by x/y refer to pixel coordinates

    
    //Set Default Colors
    graphColors = [[NSColorList alloc] initWithName:@"Graph Colors"];
      [graphColors setColor:[ NSColor whiteColor ] forKey:@"background"];
      [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.6)] forKey:@"xMajor"  ];
      [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.6)] forKey:@"yMajor"  ];
      [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"xMinor"  ];
      [graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"yMinor"  ];
      [graphColors setColor:[ NSColor blackColor ] forKey:@"xaxis"     ];
      [graphColors setColor:[ NSColor blackColor ] forKey:@"yaxis"     ];
    
    
    
    //Set Default Strings
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];[pStyle setAlignment:NSCenterTextAlignment]; //lets me make text centered in String Attributes - now using manually centered text
    xlabel = [[NSAttributedString alloc] initWithString:@"X Axis Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont paletteFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, pStyle, NSParagraphStyleAttributeName,nil]];
    ylabel = [[NSAttributedString alloc] initWithString:@"Y Axis Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont paletteFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, pStyle, NSParagraphStyleAttributeName,nil]];
    title  = [[NSAttributedString alloc] initWithString:@"Title Text"   attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont systemFontSize  ]], NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, pStyle, NSParagraphStyleAttributeName,nil]];
    
    
    //Set Flags
    drawXAxisFlag  = YES; drawYAxisFlag    = YES;
    drawXTickMarks = YES; drawYTickMarks     = YES;
    drawXNumsFlag  = NO ; drawYNumsFlag      = NO ;
    drawXGridFlag  = YES; drawYGridFlag      = YES;
    drawXLabelFlag = YES; drawYLabelFlag     = YES;
    drawTitleFlag  = YES; drawBackgroundFlag = YES;

    
    //Set Drawing Constants
    labelPadding   = 2;
    titlePadding     = 4;
    
    xMinorLineCount  = 0;
    yMinorLineCount  = 0;
    
    majorLineWidth   = 1;
    minorLineWidth   = 1;
    axisLineWidth    = 1;
    
    lineDashPattern[0]  = 4;  //segment painted with stroke color
    lineDashPattern[1]  = 5;  //segment not painted with a color
  }
  
  return self;
}

- (void)dealloc
{
  [graphColors release];
  [super dealloc];
}

- (float)titleHeight
{
  if (drawTitleFlag)
    return [title size].height + titlePadding;

  return 0;
}

- (float)xLabelHeight
{
  if (drawXLabelFlag)
    return [xlabel size].height + labelPadding;

  return 0;
}

- (float)yLabelWidth
{
  [ylabel size];
  if (drawYLabelFlag)
    return [ylabel size].height + labelPadding;

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
  if (drawTitleFlag)
  [title drawInRect:NSMakeRect(NSMinX(rect) + [self yLabelWidth], NSMaxY(rect) - [title size].height, NSWidth(rect) - NSMinX(rect) - [self yLabelWidth], [title size].height)];
}

- (void)drawXLabel:(NSRect)rect
{
  if (drawXLabelFlag)
    [xlabel drawInRect:NSMakeRect(NSMinX(rect) + [self yLabelWidth], NSMinY(rect), NSWidth(rect) - NSMinX(rect) - [self yLabelWidth], [xlabel size].height)];
}

- (void)drawYLabel:(NSRect)rect
{
  if (drawYLabelFlag)
  {
    NSAffineTransform *transform = [NSAffineTransform transform];
    NSGraphicsContext *context   = [NSGraphicsContext currentContext];
  
    [transform rotateByDegrees:90.0];
    
    [context saveGraphicsState];
    [transform concat];
  
    [ylabel drawInRect:NSMakeRect( [self xLabelHeight], -[ylabel size].height, NSMaxY(rect) - [self titleHeight] - [self xLabelHeight], [ylabel size].height)];

    [context restoreGraphicsState];
  }
}


- (void)drawBackground:(NSRect)rect
{
  if (drawBackgroundFlag)
  {
    [[graphColors colorWithKey:@"background"] set];
    NSRectFill(rect);
  }
}


- (void)drawXGrid:(NSRect)rect
{
  if (drawXGridFlag)
  {
    NSBezierPath *majorGridLines = [[NSBezierPath alloc] init]; //creates series of lines that will be gridlines on x
    NSBezierPath *minorGridLines = [[NSBezierPath alloc] init];
    NSBezierPath *tickMarks      = [[NSBezierPath alloc] init];
    
    const float xMax = NSMaxX(rect);  //bounds of graph - stored as constants
    const float xMin = NSMinX(rect);  // for preformance reasons(used often)
    const float yMax = NSMaxY(rect);
    const float yMin = NSMinY(rect);
    
    const float xratio = (gMax - gMin)/(xMax - xMin); //ratio ÆData/ÆCoordinate -> dg/dx
    
    const float xorigin = (0 - gMin)/(xratio) + xMin; //x component of the origin
    
    const float xScale = gScale / xratio; //transform scale
    
    float x;   //view coordinate x
    
    for (x = xorigin - floor((xorigin-xMin+1)/xScale)*xScale; x <= xMax+xScale; x += xScale) //Begin 1 scale unit outside of graph
    {                                         //End 1 scale unit outside of graph
      [majorGridLines moveToPoint:NSMakePoint(x,yMax)];
      [majorGridLines lineToPoint:NSMakePoint(x,yMin)];
      
      float minor;
      
      for(minor = 1; minor < xMinorLineCount; minor++)
      {
        [minorGridLines moveToPoint:NSMakePoint(x+minor/xMinorLineCount*xScale,yMax)];
        [minorGridLines lineToPoint:NSMakePoint(x+minor/xMinorLineCount*xScale,yMin)];
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
}

- (void)drawYGrid:(NSRect)rect
{
  if (drawYGridFlag)
  {
    NSBezierPath *majorGridLines = [[NSBezierPath alloc] init]; //creates series of lines that will be gridlines on y
    NSBezierPath *minorGridLines = [[NSBezierPath alloc] init];
    
    const float xMax = NSMaxX(rect);  //bounds of graph - stored as constants
    const float xMin = NSMinX(rect);  // for preformance reasons(used often)
    const float yMax = NSMaxY(rect);
    const float yMin = NSMinY(rect);

    const float yratio = (hMax - hMin)/(yMax - yMin); //ratio ÆData/ÆCoordinate -> dh/dy

    const float yorigin = (0 - hMin)/(yratio) + yMin; //y component of the origin

    const float yScale = hScale / yratio; //transform scale
    
    float  y;   //view coordinate y
    
    for(y = yorigin - floor((yorigin-yMin)/yScale+1)*yScale; y <= yMax+yScale; y += yScale) //Begin 1 scale unit outside of graph
      {                                         //End 1 scale unit outside of graph
      [majorGridLines moveToPoint:NSMakePoint(xMax,y)];
      [majorGridLines lineToPoint:NSMakePoint(xMin,y)];
      
      float minor;
      
      for(minor=1; minor < yMinorLineCount; minor++)
      {
        [minorGridLines moveToPoint:NSMakePoint(xMax, y+minor/yMinorLineCount*yScale)];
        [minorGridLines lineToPoint:NSMakePoint(xMin, y+minor/yMinorLineCount*yScale)];
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
}

- (void)drawXAxis:(NSRect)rect
{
  if (drawXAxisFlag)
  {
    //Create Axis Path & Format it
    NSBezierPath *axis      = [[NSBezierPath alloc] init];
    NSBezierPath *tickMarks = [[NSBezierPath alloc] init];
    [[graphColors colorWithKey:@"xaxis"] set];
    [axis      setLineWidth:axisLineWidth];
    [tickMarks setLineWidth:axisLineWidth];
    
    //find y coordinate where h = 0 - use abbreviated transformation
    const float xMax = NSMaxX(rect);
    const float xMin = NSMinX(rect);
    const float yMax = NSMaxY(rect);
    const float yMin = NSMinY(rect);
    
    const float xratio = (gMax - gMin)/(xMax - xMin); //ratio ÆData/ÆCoordinate -> dg/dx
    
    const float xorigin = (0 - gMin)/(xratio) + xMin; //x component of the origin
    
    const float xScale = gScale / xratio; //transform scale
      
    float y = (0 - hMin)/((hMax - hMin)/(yMax - yMin)) + yMin;
    
    //draw axis
    if (y > yMax)  //if axis is higher than graph draw dashed axis at top
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
      
      //draw line at y = yMax
      y = yMax;
    }
    else if (y < yMin) //if axis is lower than graph draw dashed axis at bottom
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
          
      //draw line at y = yMain
      y = yMin;
    }
    
    [axis moveToPoint:NSMakePoint(xMin,y)];
    [axis lineToPoint:NSMakePoint(xMax,y)];
    
    if (drawXTickMarks)
    {
      float x;
      for(x = xorigin - floor((xorigin-xMin+1)/xScale)*xScale; x <= xMax+xScale; x += xScale) //Begin 1 scale unit outside of graph
        {                                         //End 1 scale unit outside of graph
        [tickMarks moveToPoint:NSMakePoint(x,y-3)];
        [tickMarks lineToPoint:NSMakePoint(x,y+3)];
      }
    }
    
    [axis      stroke];
    [tickMarks stroke];
      
    [axis      release];
    [tickMarks release];
  }
}


- (void)drawYAxis:(NSRect)rect
{
  if (drawYAxisFlag)
  {
    //Create Axis Path & Format it
    NSBezierPath *axis      = [[NSBezierPath alloc] init];
    NSBezierPath *tickMarks = [[NSBezierPath alloc] init];
    [[graphColors colorWithKey:@"yaxis"] set];   
    [axis      setLineWidth:axisLineWidth];
    [tickMarks setLineWidth:axisLineWidth];
    
    //find y coordinate where h = 0 - use abbreviated transformation
    const float xMax = NSMaxX(rect);
    const float xMin = NSMinX(rect);
    const float yMax = NSMaxY(rect);
    const float yMin = NSMinY(rect);
    
    const float yratio = (hMax - hMin)/(yMax - yMin); //ratio ÆData/ÆCoordinate -> dh/dy

    const float yorigin = (0 - hMin)/(yratio) + yMin; //y component of the origin

    const float yScale = hScale / yratio; //transform scale
    
    float x = (0 - gMin)/((gMax - gMin)/(xMax - xMin)) + xMin;
    
    //draw axis
    if (x > xMax)  //if axis is higher than graph draw dashed axis at top
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
      
      //draw line at x = xMax
      x = xMax;
    }
    else if (x < xMin) //if axis is lower than graph draw dashed axis at bottom
    {
      //make line dashed with pattern
      [axis setLineDash: lineDashPattern count: 2 phase: 0.0];
          
      //draw line at x = xMin
      x = xMin;
      }
    
    [axis moveToPoint:NSMakePoint(x,yMin)];
    [axis lineToPoint:NSMakePoint(x,yMax)];
    
    if (drawYTickMarks)
    {
      float y;
      for(y = yorigin - floor((yorigin-yMin)/yScale+1)*yScale; y <= yMax+yScale; y += yScale) //Begin 1 scale unit outside of graph
      {                                         //End 1 scale unit outside of graph
        [tickMarks moveToPoint:NSMakePoint(x-3,y)];
        [tickMarks lineToPoint:NSMakePoint(x+3,y)];
      }
    }
      
    [axis      stroke];
    [tickMarks stroke];
      
    [axis      release];
    [tickMarks release];
  }
}


- (NSData *)graphImage
{
  return [self dataWithPDFInsideRect:[self bounds]];
}







//*********Customization Methods********************
- (void)setXMin:(float)bound
{
  if (bound >= gMax)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid lower bound" userInfo:nil] raise];
  else
    gMin = bound;
  [self setNeedsDisplay:YES];
}

- (void)setXMax:(float)bound
{
  if (bound <= gMin)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid upper bound" userInfo:nil] raise];
  else
    gMax = bound;
  [self setNeedsDisplay:YES];
}

- (void)setXScale:(float)scale
{
  gScale = scale;
  [self setNeedsDisplay:YES];
}

- (void)setXMinorLineCount:(unsigned)count
{
  xMinorLineCount = count;
  [self setNeedsDisplay:YES];
}

- (void)setYMin:(float)bound
{
  if (bound >= hMax)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid lower bound" userInfo:nil] raise];
  else
    hMin = bound;
  [self setNeedsDisplay:YES];
}

- (void)setYMax:(float)bound
{
  if (bound <= hMin)
    [[NSException exceptionWithName:@"NSRangeException" reason:@"Invalid upper bound" userInfo:nil] raise];
  else
    hMax = bound;
  [self setNeedsDisplay:YES];
}

- (void)setYScale:(float)scale
{
  hScale = scale;
  [self setNeedsDisplay:YES];
}

- (void)setYMinorLineCount:(unsigned)count
{
  yMinorLineCount = count;
  [self setNeedsDisplay:YES];
}

- (void)setShowTitle :(BOOL)state
{
  drawTitleFlag  = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowXLabel:(BOOL)state
{
  drawXLabelFlag = state;
  [self setNeedsDisplay:YES];
}
- (void)setShowXAxis :(BOOL)state
{
  drawXAxisFlag  = state;
  [self setNeedsDisplay:YES];
}
- (void)setShowXGrid :(BOOL)state
{
  drawXGridFlag  = state;
  [self setNeedsDisplay:YES];
}
- (void)setShowXTickMarks:(BOOL)state
{
  drawXTickMarks = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowYLabel:(BOOL)state
{
  drawYLabelFlag = state;
  [self setNeedsDisplay:YES];
}
- (void)setShowYAxis :(BOOL)state
{
  drawYAxisFlag  = state;
  [self setNeedsDisplay:YES];
}
- (void)setShowYGrid :(BOOL)state
{
  drawYGridFlag  = state;
  [self setNeedsDisplay:YES];
}
- (void)setShowYTickMarks:(BOOL)state
{
  drawYTickMarks = state;
  [self setNeedsDisplay:YES];
}

- (void)setShowBackground:(BOOL)state
{
  drawBackgroundFlag = state;
  [self setNeedsDisplay:YES];
}


- (void)setXAxisColor :(NSColor *)color
{
  [graphColors setColor:color forKey:@"xaxis"];
  [self setNeedsDisplay:YES];
}
- (void)setXGridColor :(NSColor *)color
{
  [graphColors setColor:color forKey:@"xMajor"];
  [self setNeedsDisplay:YES];
}

- (void)setYAxisColor :(NSColor *)color
{
  [graphColors setColor:color forKey:@"yaxis"];
  [self setNeedsDisplay:YES];
}
- (void)setYGridColor :(NSColor *)color
{
  [graphColors setColor:color forKey:@"yMajor"];
  [self setNeedsDisplay:YES];
}

- (void)setBackgroundColor:(NSColor *)color
{
  [graphColors setColor:color forKey:@"background"];
  [self setNeedsDisplay:YES];
}



- (void)setTitle:(NSAttributedString *)string
{
  [title release];
  title = string;
  [title retain];
  
  [self setNeedsDisplay:YES];
}
- (void)setXLabel:(NSAttributedString *)string
{
  [xlabel release];
  xlabel = string;
  [xlabel retain];
  
  [self setNeedsDisplay:YES];
}
- (void)setYLabel:(NSAttributedString *)string
{
  [ylabel release];
  ylabel = string;
  [ylabel retain];
  
  [self setNeedsDisplay:YES];
  }
- (NSAttributedString *)title
{return title;}
- (NSAttributedString *)xLabel
{return xlabel;}
- (NSAttributedString *)yLabel
{return ylabel;}

//************State Methods****************
- (float)xMin
{return gMin;}
- (float)xMax
{return gMax;}
- (float)xScale
{return gScale;}
- (unsigned)xMinorLineCount
{return xMinorLineCount;}

- (float)yMin
{return hMin;}
- (float)yMax
{return hMax;}
- (float)yScale
{return hScale;}
- (unsigned)yMinorLineCount
{return yMinorLineCount;}

- (BOOL)showTitle
{return drawTitleFlag;}

- (BOOL)showXLabel
{return drawXLabelFlag;}
- (BOOL)showXAxis
{return drawXAxisFlag;}
- (BOOL)showXGrid
{return drawXGridFlag;}
- (BOOL)showXTickMarks
{return drawXTickMarks;}

- (BOOL)showYLabel
{return drawYLabelFlag;}
- (BOOL)showYAxis
{return drawYAxisFlag;}
- (BOOL)showYGrid
{return drawYGridFlag;}
- (BOOL)showYTickMarks
{return drawYTickMarks;}

- (BOOL)showBackground
{return drawBackgroundFlag;}


- (NSColor *)xAxisColor
{return [graphColors colorWithKey:@"xaxis"];}
- (NSColor *)xGridColor
{return [graphColors colorWithKey:@"xMajor"];}

- (NSColor *)yAxisColor
{return [graphColors colorWithKey:@"yaxis"];}
- (NSColor *)yGridColor
{return [graphColors colorWithKey:@"yMajor"];}

- (NSColor *)backgroundColor
{return [graphColors colorWithKey:@"background"];}



@end
