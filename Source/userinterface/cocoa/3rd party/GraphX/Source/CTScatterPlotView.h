//
//  CTScatterPlotView.h
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "CTGraphView.h"

@interface NSObject(CTScatterPlotViewDataSource)
- (NSInteger)numberOfSeries;
- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index inSeries:(NSInteger)series;
@end

@interface CTScatterPlotView : CTGraphView
{
  BOOL showCurve , showFill;	//Flags to turn on/off different components of CTGraphView
  
  float curveLineWidth;   //width of the curve
  
  NSMutableArray*  curvePaths;
  NSMutableArray*  displacementPaths;
}

- (void)setDataSource:(id)inDataSource;
- (void)setDelegate:(id)inDelegate;

- (void)drawGraph:(NSRect)rect;		//Draws the Actual Graph - Curve and area under Curve (if Flags are Set)

@property (assign) BOOL showCurve;
@property (assign) BOOL showFill;

@property (retain) NSColor* curveColor;
@property (retain) NSColor* fillColor;

- (void)setCurveColor:(NSColor*)color forSeries:(NSInteger)series;
- (NSColor*)curveColorForSeries:(NSInteger)series;

@end
