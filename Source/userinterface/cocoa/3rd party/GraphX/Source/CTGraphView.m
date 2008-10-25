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
- (float)xValueHeight;   //Gives amount of space used by XAxis Label size depends on if flag is set
- (float)yLabelWidth ;   //Gives amount of space used by YAxis Label size depends on if flag is set
- (float)maxYValueWidth;

- (float)xAxisSpace;        // space needed for x axis decorations
- (float)yAxisSpace;        // space needed for y axis decorations

- (float)topSpace;
- (float)rightSpace;

- (void)drawTitle :(NSRect)rect;    //Will draw title at the top of the Graph
- (void)drawXLabel:(NSRect)rect;    //Will draw X Axis Label - if Flag is set
- (void)drawYLabel:(NSRect)rect;    //Will draw Y Axis Label - if Flag is set

- (void)drawXValues:(NSRect)rect;    //Will draw Y Value Labels - if Flag is set
- (void)drawYValues:(NSRect)rect;    //Will draw Y Value Labels - if Flag is set

- (void)drawBackground:(NSRect)rect;//Fills the Graph Region

- (void)drawXGrid:(NSRect)rect;     //Will draw Vertical Gridlines
- (void)drawYGrid:(NSRect)rect;     //Will draw Horizontal Gridlines

- (void)drawXAxis:(NSRect)rect;     //Will draw X Axis line, tick marks, numbers
- (void)drawYAxis:(NSRect)rect;     //Will draw Y Axis line, tick marks, numbers

@end

#pragma mark -

@implementation CTGraphView

static const float kYLabelAxisOffset = 2.0f;
static const float kXLabelAxisOffset = 2.0f;
static const float kTickMarkLength = 4.0f;

@synthesize dataSource;
@synthesize delegate;

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
@synthesize externalTickMarks;

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

@synthesize xAxisValueTextAttributes;
@synthesize yAxisValueTextAttributes;

+ (NSDictionary*)defaultXAxisValueAttributes
{
    static NSDictionary* sAttributes = nil;

    if (!sAttributes)
    {
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSCenterTextAlignment];

        sAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
             [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
                                               [NSColor blackColor], NSForegroundColorAttributeName,
                                                             pStyle, NSParagraphStyleAttributeName,
                                                                    nil] retain];
        [pStyle release];
    }
    return sAttributes;
}

+ (NSDictionary*)defaultYAxisValueAttributes
{
    static NSDictionary* sAttributes = nil;

    if (!sAttributes)
    {
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSRightTextAlignment];

        sAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
             [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
                                               [NSColor blackColor], NSForegroundColorAttributeName,
                                                             pStyle, NSParagraphStyleAttributeName,
                                                                    nil] retain];
        [pStyle release];
    }
    return sAttributes;
}

+ (NSDictionary*)defaultAxisLabelAttributes
{
    static NSDictionary* sAttributes = nil;

    if (!sAttributes)
    {
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSCenterTextAlignment];

        sAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont paletteFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
                                               [NSColor blackColor], NSForegroundColorAttributeName,
                                                             pStyle, NSParagraphStyleAttributeName,
                                                                    nil] retain];
        [pStyle release];
    }
    return sAttributes;
}

+ (NSDictionary*)defaultTitleAttributes
{
    static NSDictionary* sAttributes = nil;

    if (!sAttributes)
    {
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSCenterTextAlignment];

        sAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
              [NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName,
                                               [NSColor blackColor], NSForegroundColorAttributeName,
                                                             pStyle, NSParagraphStyleAttributeName,
                                                                    nil] retain];
        [pStyle release];
    }
    return sAttributes;
}

// 10.5 and later only
+ (NSSet *)keyPathsForValuesAffectingNeedsRecomputation
{
    return [NSSet setWithObjects:@"xMin",
                                @"xMax",
                                @"yMin",
                                @"yMax",
                                @"showTitle",
                                @"showXLabel",
                                @"showXAxis",
                                @"showXValues",
                                @"showXGrid",
                                @"showXTickMarks",
                                @"showYLabel",
                                @"showYAxis",
                                @"showYValues",
                                @"showYGrid",
                                @"showYTickMarks",
                                @"showBackground",
                                @"externalTickMarks",
                                @"xAxisColor",
                                @"xGridColor",
                                @"yAxisColor",
                                @"yGridColor",
                                @"backgroundColor",
                                @"title",
                                @"xLabel",
                                @"yLabel",
                                @"xAxisValueTextAttributes",
                                @"yAxisValueTextAttributes",
                                nil];
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
        xLabel = [[NSAttributedString alloc] initWithString:@"X Axis Label" attributes:[CTGraphView defaultAxisLabelAttributes]];
        yLabel = [[NSAttributedString alloc] initWithString:@"Y Axis Label" attributes:[CTGraphView defaultAxisLabelAttributes]];

        title  = [[NSAttributedString alloc] initWithString:@"Title Text"   attributes:[CTGraphView defaultTitleAttributes]];

        self.xAxisValueTextAttributes = [CTGraphView defaultXAxisValueAttributes];
        self.yAxisValueTextAttributes = [CTGraphView defaultYAxisValueAttributes];

        //Set Flags
        showTitle  = YES;
        showBackground = YES;
        externalTickMarks = YES;

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

        graphDirty = YES;
        
        [self setPostsBoundsChangedNotifications:YES];
        [self setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewBoundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewBoundsDidChange:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:self];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.dataSource = nil;
    self.delegate = nil;

    [graphColors release];
    self.xLabel = nil;
    self.yLabel = nil;
    self.title = nil;
    self.xAxisValueTextAttributes = nil;
    self.yAxisValueTextAttributes = nil;

    [super dealloc];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if (newWindow)
    {
        [self addObserver:self
               forKeyPath:@"needsRecomputation"
                  options:0
                  context:NULL];
    }
    else
    {
        [self removeObserver:self forKeyPath:@"needsRecomputation"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"needsRecomputation"])
    {
        [self dataChanged];
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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

- (float)xValueHeight
{
    float xValHeight = 0.0;
    float yValSpace = 0.0;

    if (showXValues)
    {
        NSMutableAttributedString* xLabelString = [[[NSMutableAttributedString alloc] initWithString:@"99"
                                                                                         attributes:xAxisValueTextAttributes] autorelease];
        xValHeight = [xLabelString size].height;
    }

    if (showYValues)
    {
        NSMutableAttributedString* yLabelString = [[[NSMutableAttributedString alloc] initWithString:@"99"
                                                                                         attributes:yAxisValueTextAttributes] autorelease];
        yValSpace = [yLabelString size].height / 2.0f;
    }

    return MAX(xValHeight, yValSpace);
}

- (float)maxYValueWidth
{
    float maxYWidth = 0.0f;
    if (showYValues)
    {
        NSString* formattedString = [NSString stringWithFormat:@"%.6g", yMax];

        NSMutableAttributedString* yLabelString = [[[NSMutableAttributedString alloc] initWithString:formattedString
                                                                                         attributes:yAxisValueTextAttributes] autorelease];
        maxYWidth = kYLabelAxisOffset + [yLabelString size].width;
    }
    return maxYWidth;
}

- (float)yLabelWidth
{
    if (showYLabel)
    {
        [yLabel size];

        return [yLabel size].height + labelPadding;
    }
    return 0;
}

- (float)xAxisSpace
{
    return [self xValueHeight] + [self xLabelHeight] + (externalTickMarks ? kTickMarkLength : 0);
}

- (float)yAxisSpace
{
    return [self maxYValueWidth] + [self yLabelWidth] + (externalTickMarks ? kTickMarkLength : 0);
}

- (float)topSpace
{
    float titleHeight = [self titleHeight];
    float yValueSpace = 0;
    if (showYValues)
    {
        NSMutableAttributedString* yValueString = [[[NSMutableAttributedString alloc] initWithString:@"99"
                                                                                         attributes:yAxisValueTextAttributes] autorelease];
        yValueSpace = [yValueString size].height / 2.0f;
    }
    return titleHeight + yValueSpace;
}

// FIXME: need to subclass for histogram view
- (float)rightSpace
{
    if (showXValues)
    {
        NSMutableAttributedString* xValueString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.6g", xMax]
                                                                                         attributes:xAxisValueTextAttributes] autorelease];
        return [xValueString size].width / 2.0f;
    }
    return 0.0f;
}

- (NSRect)graphRectForRect:(NSRect)inRect
{
    float tHeight = [self topSpace];
    float rightSpace = [self rightSpace];
    float xHeight = [self xAxisSpace];
    float yWidth  = [self yAxisSpace];

    NSRect graphRect =  NSMakeRect(NSMinX(inRect) + yWidth, NSMinY(inRect) + xHeight, //Make Adjusted Graph
                                   NSWidth(inRect) - yWidth - rightSpace, NSHeight(inRect) - xHeight - tHeight);

    return NSIntegralRect(graphRect);
}


#pragma mark -

- (void)drawGraph:(NSRect)graphRect
{
    // overridden by subclasses
}

- (void)drawRect:(NSRect)inDirtyRect   //mainly function calls to more complex implementation
{
    [self recomputeGraphIfNecessary];

    NSRect rect = [self bounds];

    //First Draw the Title, X/Y Axis & Labels
    [self drawTitle :rect];
    [self drawXLabel:rect];
    [self drawYLabel:rect];

    NSRect graphRect = [self graphRectForRect:rect];

    {
        NSGraphicsContext* context   = [NSGraphicsContext currentContext];
        [context saveGraphicsState];

        NSRectClip(graphRect);

        //Draw the Background
        [self drawBackground:(graphRect)];

        //Draw the Grid Lines
        [self drawXGrid:graphRect];
        [self drawYGrid:graphRect];

        //Draw Curve and Area
        [self drawGraph:graphRect];

        [context restoreGraphicsState];
    }

    // Finish up by drawing the X and Y Axis (dependent on flags)
    [self drawXAxis:graphRect];
    [self drawYAxis:graphRect];

    [self drawXValues:graphRect];
    [self drawYValues:graphRect];
}
  
- (void)drawTitle:(NSRect)rect;
{
    if (showTitle)
    {
        float ySpace = [self yAxisSpace];
        [title drawInRect:NSMakeRect(NSMinX(rect) + ySpace, NSMaxY(rect) - [title size].height,
                                     NSWidth(rect) - NSMinX(rect) - ySpace, [title size].height)];
    }
}

- (void)drawXLabel:(NSRect)rect
{
    if (showXLabel)
    {
        float ySpace = [self yAxisSpace];
        [xLabel drawInRect:NSMakeRect(NSMinX(rect) + ySpace, NSMinY(rect),
                                      NSWidth(rect) - NSMinX(rect) - ySpace, [xLabel size].height)];
    }
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
  
    [yLabel drawInRect:NSMakeRect([self xAxisSpace], -[yLabel size].height,
                                  NSMaxY(rect) - [self topSpace] - [self xAxisSpace], [yLabel size].height)];

    [context restoreGraphicsState];
}

- (void)drawXValues:(NSRect)rect
{
    if (!showXValues)
        return;

    const float minXBounds = NSMinX(rect);
    const float maxXBounds = NSMaxX(rect);

    const float minYBounds = NSMinY(rect);
//    const float maxYBounds = NSMaxY(rect);
    
    const float xRatio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ∆Data/∆Coordinate -> dg/dx

    float valueHeight = [self xValueHeight];
    float labelBottom = minYBounds - valueHeight - kXLabelAxisOffset - (externalTickMarks ? kTickMarkLength : 0.0f);
    
    NSMutableAttributedString* labelString = [[[NSMutableAttributedString alloc] initWithString:@""
                                                                                     attributes:xAxisValueTextAttributes] autorelease];

    int numDivisions = (xMax - xMin) / xScale;
    if (numDivisions > 20)
        numDivisions = 20;      // HACK
    
    int i;
    for (i = 0; i <= numDivisions; ++i)
    {
        float xValue = xMin + i * (xMax - xMin) / numDivisions;
        float xPos = minXBounds + (xValue - xMin) / xRatio;
        NSString* formattedString = [[NSString alloc] initWithFormat:@"%.6g", xValue];

        [labelString replaceCharactersInRange:NSMakeRange(0, [labelString length]) withString:formattedString];
        [labelString setAttributes:xAxisValueTextAttributes range:NSMakeRange(0, [labelString length])];

        [formattedString release];
        
        float textWidth = [labelString size].width;
        NSRect textRect = NSMakeRect(xPos - textWidth / 2.0f, labelBottom,
                                    textWidth, valueHeight);

        [labelString drawInRect:textRect];
    }
}

- (void)drawYValues:(NSRect)rect
{
    if (!showYValues)
        return;

    const float minXBounds = NSMinX(rect);
    //const float maxXBounds = NSMaxX(rect);

    const float minYBounds = NSMinY(rect);
    const float maxYBounds = NSMaxY(rect);
    
    const float yRatio = (yMax - yMin) / (maxYBounds - minYBounds); //ratio ∆Data/∆Coordinate -> dh/dy
    
    float maxLabelWidth = [self maxYValueWidth];
    float labelRightPos = minXBounds - kYLabelAxisOffset - (externalTickMarks ? kTickMarkLength : 0.0f);
    
    NSMutableAttributedString* labelString = [[[NSMutableAttributedString alloc] initWithString:@""
                                                                                     attributes:yAxisValueTextAttributes] autorelease];
    int numDivisions = (yMax - yMin) / yScale;
    if (numDivisions > 20)
        numDivisions = 20;      // HACK

    int i;
    for (i = 0; i <= numDivisions; ++i)
    {
        float yValue = yMin + i * (yMax - yMin) / numDivisions;
        float yPos = minYBounds + (yValue - yMin) / yRatio;
        NSString* formattedString = [[NSString alloc] initWithFormat:@"%.6g", yValue];

        [labelString replaceCharactersInRange:NSMakeRange(0, [labelString length]) withString:formattedString];
        [labelString setAttributes:yAxisValueTextAttributes range:NSMakeRange(0, [labelString length])];

        [formattedString release];
        
        float textHeight = [labelString size].height;
        NSRect textRect = NSMakeRect(labelRightPos - maxLabelWidth, yPos - textHeight / 2.0f,
                                    maxLabelWidth, textHeight);

        [labelString drawInRect:textRect];
    }
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

    const float xRatio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ∆Data/∆Coordinate -> dg/dx

    const float xOrigin = (0 - xMin)/xRatio + minXBounds; //x component of the origin

    const float scaleX = xScale / xRatio; //transform scale

    float x;   //view coordinate x

    for (x = xOrigin - floor((xOrigin - minXBounds + 1) / scaleX) * scaleX; x <= maxXBounds + scaleX; x += scaleX) //Begin 1 scale unit outside of graph
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

    const float yRatio = (yMax - yMin)/(maxYBounds - minYBounds); //ratio ∆Data/∆Coordinate -> dh/dy

    const float yOrigin = (0 - yMin)/(yRatio) + minYBounds; //y component of the origin

    const float scaleY = yScale / yRatio; //transform scale
    
    float  y;   //view coordinate y
    for (y = yOrigin - floor((yOrigin - minYBounds) / scaleY + 1) * scaleY; y <= maxYBounds + scaleY; y += scaleY) //Begin 1 scale unit outside of graph
    {                                         //End 1 scale unit outside of graph
      if (y > minYBounds)
      {
        [majorGridLines moveToPoint:NSMakePoint(maxXBounds, y)];
        [majorGridLines lineToPoint:NSMakePoint(minXBounds, y)];
      }
      
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
    NSBezierPath* axis      = [[NSBezierPath alloc] init];
    NSBezierPath* tickMarks = [[NSBezierPath alloc] init];

    [[graphColors colorWithKey:@"xaxis"] set];
    [axis      setLineWidth:axisLineWidth];
    [tickMarks setLineWidth:axisLineWidth];
    
    //find y coordinate where h = 0 - use abbreviated transformation
    const float maxXBounds = NSMaxX(rect);
    const float minXBounds = NSMinX(rect);
    const float maxYBounds = NSMaxY(rect);
    const float minYBounds = NSMinY(rect);
    
    const float xRatio = (xMax - xMin)/(maxXBounds - minXBounds); //ratio ∆Data/∆Coordinate -> dg/dx
    
    const float xOrigin = (0 - xMin)/xRatio + minXBounds; //x component of the origin
    
    const float scaleX = xScale / xRatio; //transform scale
      
    float y = (0 - yMin) / ((yMax - yMin)/(maxYBounds - minYBounds)) + minYBounds;
    
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
      float tickYStart = y;
      float tickYEnd = externalTickMarks ? y - kTickMarkLength : y + kTickMarkLength;
      
      float x;
      for (x = xOrigin - floor((xOrigin - minXBounds + 1) / scaleX) * scaleX; x <= maxXBounds + scaleX; x += scaleX) // Begin 1 scale unit outside of graph
      {
        [tickMarks moveToPoint:NSMakePoint(x, tickYStart)];
        [tickMarks lineToPoint:NSMakePoint(x, tickYEnd)];
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
    
    const float yRatio = (yMax - yMin)/(maxYBounds - minYBounds); //ratio ∆Data/∆Coordinate -> dh/dy

    const float yOrigin = (0 - yMin)/(yRatio) + minYBounds; //y component of the origin

    const float scaleY = yScale / yRatio; //transform scale
    
    float x = (0 - xMin)/((xMax - xMin) / (maxXBounds - minXBounds)) + minXBounds;
    
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
    
    [axis moveToPoint:NSMakePoint(x, minYBounds)];
    [axis lineToPoint:NSMakePoint(x, maxYBounds)];
    
    if (showYTickMarks)
    {
      float tickXStart = x;
      float tickXEnd = externalTickMarks ? x - kTickMarkLength : x + kTickMarkLength;

      float y;
      for (y = yOrigin - floor((yOrigin - minYBounds) / scaleY + 1) * scaleY; y <= maxYBounds + scaleY; y += scaleY) //Begin 1 scale unit outside of graph
      {                                         //End 1 scale unit outside of graph
        if (y >= minYBounds)
        {
            [tickMarks moveToPoint:NSMakePoint(tickXStart, y)];
            [tickMarks lineToPoint:NSMakePoint(tickXEnd, y)];
        }
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

- (void)dataChanged
{
    graphDirty = YES;
    [self setNeedsDisplay:YES];
}

- (void)recomputeGraphIfNecessary
{
    if (graphDirty)
    {
        if ([delegate respondsToSelector:@selector(willUpdateGraphView:)])
            [delegate willUpdateGraphView:self];

        @try
        {
            [self recomputeGraph:[self graphRectForRect:[self bounds]]];
        }
        @catch(NSException* e)
        {
            NSLog(@"Caught exception %@ recomputing graph %@", e, self);
        }
        
        if ([delegate respondsToSelector:@selector(didUpdateGraphView:)])
            [delegate didUpdateGraphView:self];

        graphDirty = NO;
    }
}

- (void)recomputeGraph:(NSRect)rect
{
    // for subclasses to override
}

- (void)viewBoundsDidChange:(NSNotification*)inNotification
{
    // we need to recompute the bezier paths etc
    [self dataChanged];
}

#pragma mark -

- (NSColor *)xAxisColor
{
    return [graphColors colorWithKey:@"xaxis"];
}

- (void)setXAxisColor:(NSColor *)color
{
    [self willChangeValueForKey:@"xAxisColor"];
    [graphColors setColor:color forKey:@"xaxis"];
    [self didChangeValueForKey:@"xAxisColor"];
}

- (NSColor *)xGridColor
{
    return [graphColors colorWithKey:@"xMajor"];
}

- (void)setXGridColor:(NSColor *)color
{
    [self willChangeValueForKey:@"xGridColor"];
    [graphColors setColor:color forKey:@"xMajor"];
    [self didChangeValueForKey:@"xGridColor"];
}

- (NSColor *)yAxisColor
{
    return [graphColors colorWithKey:@"yaxis"];
}

- (void)setYAxisColor:(NSColor *)color
{
    [self willChangeValueForKey:@"yAxisColor"];
    [graphColors setColor:color forKey:@"yaxis"];
    [self didChangeValueForKey:@"yAxisColor"];
}

- (NSColor *)yGridColor
{
    return [graphColors colorWithKey:@"yMajor"];
}

- (void)setYGridColor:(NSColor *)color
{
    [self willChangeValueForKey:@"yGridColor"];
    [graphColors setColor:color forKey:@"yMajor"];
    [self didChangeValueForKey:@"yGridColor"];
}

- (NSColor *)backgroundColor
{
    return [graphColors colorWithKey:@"background"];
}

- (void)setBackgroundColor:(NSColor *)color
{
    [self willChangeValueForKey:@"backgroundColor"];
    [graphColors setColor:color forKey:@"background"];
    [self didChangeValueForKey:@"backgroundColor"];
}

#pragma mark -

- (float)xAxisLabelOffset
{
    return kXLabelAxisOffset;
}

- (float)tickMarkLength
{
    return kTickMarkLength;
}



@end
