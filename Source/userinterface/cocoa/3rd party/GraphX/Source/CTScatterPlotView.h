//
//  CTScatterPlotView.h
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "CTGraphView.h"

@interface NSObject(CTScatterPlotViewDataSource)
- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index;
@end

@interface NSObject(CTScatterPlotViewDelegate)

@end



@interface CTScatterPlotView : CTGraphView
{
  IBOutlet id dataSource;   //object that will give graph values for drawing the curve
  IBOutlet id delegate  ;   //object that will be notified when key events occur
  
  BOOL drawGraphFlag , drawFillFlag;	//Flags to turn on/off different components of CTGraphView
  
  float curveLineWidth;   //width of the curve
  
  NSBezierPath *curve;
  NSBezierPath *displacement;
}

- (void)setDataSource:(id)inDataSource;
- (void)setDelegate:(id)inDelegate;

- (void)drawGraph:(NSRect)rect;		//Draws the Actual Graph - Curve and area under Curve (if Flags are Set)

//Customization Methods
- (void)setShowCurve :(BOOL)state;
- (void)setShowFill  :(BOOL)state;

- (void)setCurveColor:(NSColor *)color;
- (void)setFillColor :(NSColor *)color;


//State Methods
- (BOOL)showCurve;
- (BOOL)showFill ;

- (NSColor *)curveColor;
- (NSColor *)fillColor ;

@end
