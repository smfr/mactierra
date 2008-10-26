//
//  CTHistogramView.h
//
//  Created by Chad Weider on Fri May 28 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "CTGraphView.h"

@interface NSObject(CTHistogramViewDataSource)
- (NSInteger)numberOfSeries;
- (float)frequencyForBucket:(NSUInteger)index label:(NSString**)outLabel inSeries:(NSInteger)series;
@end

@interface CTHistogramView : CTGraphView
{
  NSUInteger numberOfBuckets;
  
  BOOL showBorder, showFill;  //Flags to turn on/off different components of CTGraphView
  
  float borderLineWidth;   //width of the curve
  
  NSBezierPath* border;
  NSBezierPath* displacement;
}

- (void)setDataSource:(id)inDataSource;
- (void)setDelegate:(id)inDelegate;

- (void)drawGraph:(NSRect)rect;

@property (assign) NSUInteger numberOfBuckets;

@property (assign) BOOL showBorder;
@property (assign) BOOL showFill;

@property (retain) NSColor* borderColor;
@property (retain) NSColor* fillColor;

@end
