//
//  CTHistogramView.h
//
//  Created by Chad Weider on Fri May 28 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "CTGraphView.h"

@interface NSObject(CTHistogramViewDataSource)
- (float)frequencyForBucketWithLowerBound:(float)lowerBound andUpperLimit:(float)upperLimit;
@end

@interface NSObject(CTHistogramViewDelegate)

@end



@interface CTHistogramView : CTGraphView
{
  IBOutlet id dataSource;   //object that will give graph values for drawing the curve
  IBOutlet id delegate  ;   //object that will be notified when key events occur

  float bucketWidth;  //Width of Buckets(ranges for frequencies)
  
  BOOL drawBorderFlag, drawFillFlag;  //Flags to turn on/off different components of CTGraphView
  
  float borderLineWidth;   //width of the curve
  
  NSBezierPath *border;
  NSBezierPath *displacement;
}

- (void)setDataSource:(id)inDataSource;
- (void)setDelegate:(id)inDelegate;

- (void)drawGraph:(NSRect)rect;   //Draws the Actual Graph - Curve and area under Curve (if Flags are Set)

//Customization Methods
- (void)setBucketWidth:(float)width;

- (void)setShowBorder:(BOOL)state;
- (void)setShowFill  :(BOOL)state;

- (void)setBorderColor:(NSColor *)color;
- (void)setFillColor  :(NSColor *)color;


//State Methods
- (float)bucketWidth;

- (BOOL)showBorder;
- (BOOL)showFill  ;

- (NSColor *)borderColor;
- (NSColor *)fillColor  ;

@end
