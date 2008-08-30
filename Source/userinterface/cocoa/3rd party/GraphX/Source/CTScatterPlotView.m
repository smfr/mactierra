//
//  CTScatterPlotView.m
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//



#import "CTScatterPlotView.h"

@implementation CTScatterPlotView

- (id)initWithFrame:(NSRect)frameRect
  {
  if((self = [super initWithFrame:frameRect]) != nil)
	{
	//Set Default Colors
	[graphColors setColor:[ NSColor blackColor ] forKey:@"curve"];
	[graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"fill"];
	
	
	//Set Flags
	drawGraphFlag  = YES;
	drawFillFlag   = YES;
	
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
  [curve release];
  [displacement release];
  
  [super dealloc];
  }


- (void)drawGraph:(NSRect)rect
  {
  const float xMax = NSMaxX(rect);	//bounds of graph - stored as constants
  const float xMin = NSMinX(rect);	// for preformance reasons(used often)
  const float yMax = NSMaxY(rect);
  const float yMin = NSMinY(rect);
  
  const float xratio = (gMax - gMin)/(xMax - xMin); //ratio ÆData/ÆCoordinate -> dg/dx
  const float yratio = (hMax - hMin)/(yMax - yMin); //ratio ÆData/ÆCoordinate -> dh/dy
  
  const float xorigin = (0 - gMin)/(xratio) + xMin; //x component of the origin
  const float yorigin = (0 - hMin)/(yratio) + yMin; //y component of the origin
  
  //Create Curve Path then Draw Curve and Fill Area underneath
	
	//will now start sampling graph values to form graph points, then converting them to pixel points,
	//and finally feeding them into the curve
	//
	//Sampling will begin at gMin and finish off at gMax
	//  any points that return null will be ignored
	
	//the sample data point's coordinates
	unsigned index = 0;
	
	
	NSPoint tmp= NSMakePoint(1,2);
	
	NSPoint *pointPointer = &tmp;
	
	float g = gMin;
	float h = NAN; 
	
	float g_next;
	float h_next;
	
	float gMinRatio = gMin/xratio;
    float hMinRatio = hMin/yratio;
	
	float x;
	float y;
	
	[dataSource getPoint:&pointPointer atIndex:index];
	
	while(g < gMax &&  pointPointer != nil)
		{
		while((g < gMax &&  pointPointer != nil) && isnan(h))
			{
			g_next = pointPointer->x;
			h_next = pointPointer->y;
			
			if(isnan(h_next))
				{
				}
			
			
			else
				{
				x = (g_next)/(xratio) - gMinRatio + xMin;
				
				if(isfinite(h_next))							//move to the right to the point
					y = (h_next)/(yratio) - hMinRatio + yMin;
				else if(signbit(h_next))						//move to top of screen
					y = yMax + curveLineWidth;
				else											//move to bottom of screen
					y = yMin - curveLineWidth;
					
				[curve moveToPoint:NSMakePoint(x,y)];
				}
			
			g = g_next;
			h = h_next;
			[dataSource getPoint:&pointPointer atIndex:(++index)];
			}
		
		//Make sure we aren't ending with NaN
		if(g >= gMax && isnan(h))
			break;
		
		float firstPoint = g/(xratio) - gMinRatio + xMin;
		
		while(!isnan(h))
			{
			while((g < gMax &&  pointPointer != nil) && isfinite(h))
				{
				g_next = pointPointer->x;
				h_next = pointPointer->y;
				
				if(isnan(h_next))
					{
					break;
					}
				
				//Next point is valid - draw a line to it
				else
					{
					
					if(isfinite(h_next))							//line to the right to the point
						{
						x = (g_next)/(xratio) - gMinRatio + xMin;
						y = (h_next)/(yratio) - hMinRatio + yMin;
						}
					else if(signbit(h_next))						//line to top of screen
						y = yMax + curveLineWidth;
					else											//line to bottom of screen
						y = yMin - curveLineWidth;
					
					
					[curve lineToPoint:NSMakePoint(x,y)];
					}
				
				g = g_next;
				h = h_next;
				[dataSource getPoint:&pointPointer atIndex:(++index)];
				}
			
			while(!isfinite(h) && !isnan(h) && (g < gMax &&  pointPointer != nil))
				{
				g_next = pointPointer->x;
				h_next = pointPointer->y;
				
				if(isnan(h_next))
					{
					break;
					}
				
				//Next point is valid - draw a line to it
				else if(!isnan(h_next))
					{
					x = (g_next)/(xratio) - gMinRatio + xMin;
					y = signbit(h) ? yMax+curveLineWidth : yMin-curveLineWidth;
					
					[curve lineToPoint:NSMakePoint(x,y)];
					
					//Next point is valid - draw a line to it
					x = (g_next)/(xratio) - gMinRatio + xMin;
					
					if(isfinite(h_next))							//move to the right to the point
						y = (h_next)/(yratio) - hMinRatio + yMin;
					else if(signbit(h_next))						//move to top of screen
						y = yMax + curveLineWidth;
					else											//move to bottom of screen
						y = yMin - curveLineWidth;
					
					[curve lineToPoint:NSMakePoint(x,y)];
					}
				
				g = g_next;
				h = h_next;
				[dataSource getPoint:&pointPointer atIndex:(++index)];
				}
				
				if(isnan(h_next) || (g >= gMax || pointPointer == nil))
					{
					break;
					}
			}
			
			//Set points up for next segment
			g = g_next;
			h = h_next;
			
			if(drawFillFlag == YES)
				{
				//Create New path that wil be filled
				//float lastPoint = [curve currentPoint].x;
				
				[displacement appendBezierPath:curve];
				
				//move curve to x axis, then go across it to the begining of the segment
				[displacement lineToPoint:NSMakePoint(x,yorigin)];
				[displacement lineToPoint:NSMakePoint(firstPoint,yorigin)];
				
				//fill area under curve
				[[graphColors colorWithKey:@"fill"] set];
				[displacement fill];
				}
			//Draw and fill curve
			if( drawGraphFlag == YES )
				{
				[[graphColors colorWithKey:@"curve"] set];
				[curve stroke];
				}
			
			
			[curve removeAllPoints];
			[displacement removeAllPoints];
			}
   }








//*********Customization Methods********************
- (void)setShowCurve:(bool)state
	{drawGraphFlag = state;}
- (void)setShowFill:(bool)state
	{drawFillFlag = state;}


- (void)setCurveColor:(NSColor *)color
	{[graphColors setColor:color forKey:@"curve"];}
- (void)setFillColor:(NSColor *)color
	{[graphColors setColor:color forKey:@"fill"];}






//************State Methods****************
- (bool)showCurve
	{return drawGraphFlag;}
- (bool)showFill
	{return drawFillFlag;}



- (NSColor *)curveColor
	{return [graphColors colorWithKey:@"curve"];}
- (NSColor *)fillColor
	{return [graphColors colorWithKey:@"fill"];}

@end
