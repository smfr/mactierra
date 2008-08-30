//
//  CTCurveView.m
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//



#import "CTCurveView.h"

@implementation CTCurveView

- (id)initWithFrame:(NSRect)frameRect
  {
  if((self = [super initWithFrame:frameRect]) != nil)
	{
	//Set Default Resolution for X (in terms of pixel coordinates - **not in terms of a data value)
	 res = 1;
	xres = 1;
	approx = NO;
	
	//Set Default Colors
	[graphColors setColor:[ NSColor blackColor ] forKey:@"curve"];
	[graphColors setColor:[[NSColor blueColor  ] colorWithAlphaComponent:(.4)] forKey:@"fill"];
	
	
	//Set Flags
	drawGraphFlag = YES;
	drawFillFlag  = YES;

	
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
	
	//start by convert xres(a pixel increment) to gres(a graph value increment)
	// this uses a method similar to the linear transformation from above(drawing the xgrid)
	float gres = xres * (gMax - gMin)/(xMax - xMin);
	
	//will now start sampling graph values to form graph points, then converting them to pixel points,
	//and finally feeding them into the curve
	//
	//Sampling will begin at gMin and finish off at gMax
	//  any points that return null will be ignored
	
	//the sample data point's coordinates
	float g = gMin - gres;
	float h = NAN; 
	
	float g_next;
	float h_next;
	
	float gMinRatio = gMin/xratio;
    float hMinRatio = hMin/yratio;
	
	float x;
	float y;
	
	while(g < gMax)
		{
		//NaN Segment (keep continuing until a graphable point is reached)
		while(g < gMax && isnan(h))
			{
			g_next = g + gres;
			h_next = [dataSource yValueForXValue:g_next];
			
			if(isnan(h_next))
				{
				}
			
			//If the NaN Segment has ended - begin drawing points
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
			}
		
		//Make sure we aren't ending with NaN
		if(g >= gMax && isnan(h))
			break;
		
		float firstPoint = g/(xratio) - gMinRatio + xMin;
		[delegate hasDrawnFirstSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,y) inRect:rect withOrigin:NSMakePoint(xorigin,yorigin)];
		
		
		//Graphable Line Segment continue until NaN segment is once again reached
		while(!isnan(h))
			{
			while(g < gMax && isfinite(h))
				{
				g_next = g + gres;
				h_next = [dataSource yValueForXValue:g_next];
				
				[delegate hasDrawnSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,y) inRect:rect withOrigin:NSMakePoint(xorigin,yorigin)];
				
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
				}
			
			while(!isfinite(h) && !isnan(h) && g <= gMax)
				{
				g_next = g + gres;
				h_next = [dataSource yValueForXValue:g_next];
				
				[delegate hasDrawnSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,h) inRect:rect withOrigin:NSMakePoint(xorigin,yorigin)];
				
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
				}
				
				if(isnan(h_next) || g >= gMax)
					{
					break;
					}
			}
		
		[delegate hasDrawnLastSegmentDataPoint:NSMakePoint(g,h) atViewPoint:NSMakePoint(x,y) inRect:rect withOrigin:NSMakePoint(xorigin,yorigin)];
		
		//Set points up for next segment
		g = g_next;
		h = h_next;
		
		if(drawFillFlag == YES)
			{
			//Create New path that wil be filled
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


- (void)viewWillStartLiveResize
	{
	if(approx == YES)
		xres = res*9;
	}
- (void)viewDidEndLiveResize
	{
	xres = res;
	[self setNeedsDisplay:YES];
	}




//*********Customization Methods********************
- (void)setRes:(float)resolution
	{
	res = resolution;
	[self setNeedsDisplay:YES];
	}
- (void)setApproximateOnLiveResize:(bool)state
	{approx = state;}

- (void)setShowCurve:(bool)state
	{
	drawGraphFlag = state;
	[self setNeedsDisplay:YES];
	}
- (void)setShowFill:(bool)state
	{
	drawFillFlag = state;
	[self setNeedsDisplay:YES];
	}


- (void)setCurveColor:(NSColor *)color
	{
	[graphColors setColor:color forKey:@"curve"];
	[self setNeedsDisplay:YES];
	}
- (void)setFillColor:(NSColor *)color
	{
	[graphColors setColor:color forKey:@"fill"];
	[self setNeedsDisplay:YES];
	}






//************State Methods****************
- (float)res;
	{return res;}
- (bool)setApproximateOnLiveResize
	{return approx;}


- (bool)showCurve
	{return drawGraphFlag;}
- (bool)showFill
	{return drawFillFlag;}



- (NSColor *)curveColor
	{return [graphColors colorWithKey:@"curve"];}
- (NSColor *)fillColor
	{return [graphColors colorWithKey:@"fill"];}

@end
