//
//  CTGraphView.h
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface CTGraphView : NSView
{
    IBOutlet id dataSource;   //object that will give graph values for drawing the curve
    IBOutlet id delegate  ;   //object that will be notified when key events occur

    float xMin, xMax, xScale;     //Specifies the minimum/maximum values for X Axis
                                // xscale used to determine location of Vertical Gridlines & X Axix tick marks

    float yMin, yMax, yScale;     //Specifies the minimum/maximum values for Y Axis
                                // yscale used to determine location of Horizontal Gridlines & Y Axix tick marks
  
    NSColorList* graphColors;     //List of all the colors that CTGraphView will use when Drawing itself

    NSAttributedString* xLabel;
    NSAttributedString* yLabel;
    NSAttributedString* title;
  
    NSDictionary* xAxisValueTextAttributes;
    NSDictionary* yAxisValueTextAttributes;

    BOOL showTitle;
    BOOL showBackground;

    BOOL showXLabel;
    BOOL showXAxis;
    BOOL showXValues;
    BOOL showXGrid;
    BOOL showXTickMarks;

    BOOL showYLabel;
    BOOL showYAxis;
    BOOL showYValues;
    BOOL showYGrid;
    BOOL showYTickMarks;
  
    BOOL externalTickMarks;
    
    float labelPadding;       //padding(space between)layers in x and y Axis layers and Graph
    float titlePadding;       //padding(space between) Title and Graph

    unsigned xMinorLineCount;
    unsigned yMinorLineCount;

    float axisLineWidth;      //width constant for lines on x and y Axis
    float majorLineWidth;     //width of gridlines - applies to both x and y gridlines
    float minorLineWidth;     //width of gridlines - applies to both x and y gridlines

    CGFloat lineDashPattern[2]; //dashing pattern used by axis that are out of bounds
    
    BOOL graphDirty;
}

+ (NSSet *)keyPathsForValuesAffectingNeedsRecomputation;

- (NSData *)graphImage;

// Call this when the data source data changes. The graph wil be recomputed before
// the next display
- (void)dataChanged;

@property (retain) id dataSource;
@property (assign) id delegate;

@property (assign) float xMin;
@property (assign) float xMax;
@property (assign) float xScale;        // grid spacing (?)
@property (assign) unsigned xMinorLineCount;

@property (assign) float yMin;
@property (assign) float yMax;
@property (assign) float yScale;        // grid spacing (?)
@property (assign) unsigned yMinorLineCount;

@property (assign) BOOL showTitle;

@property (assign) BOOL showXLabel;
@property (assign) BOOL showXAxis;
@property (assign) BOOL showXValues;
@property (assign) BOOL showXGrid;
@property (assign) BOOL showXTickMarks;

@property (assign) BOOL showYLabel;
@property (assign) BOOL showYAxis;
@property (assign) BOOL showYValues;
@property (assign) BOOL showYGrid;
@property (assign) BOOL showYTickMarks;

@property (assign) BOOL showBackground;

@property (assign) BOOL externalTickMarks;

@property (retain) NSColor* xAxisColor;
@property (retain) NSColor* xGridColor;

@property (retain) NSColor* yAxisColor;
@property (retain) NSColor* yGridColor;

@property (retain) NSColor* backgroundColor;

@property (copy) NSAttributedString* title;
@property (copy) NSAttributedString* xLabel;
@property (copy) NSAttributedString* yLabel;

@property (retain) NSDictionary* xAxisValueTextAttributes;
@property (retain) NSDictionary* yAxisValueTextAttributes;

// for subclassers
@property (readonly) float xAxisLabelOffset;
@property (readonly) float tickMarkLength;
@property (readonly) float xValueHeight;

- (void)recomputeGraphIfNecessary;
- (void)recomputeGraph:(NSRect)rect;

@end

@interface NSObject(CTGraphViewDelegate)

- (void)willUpdateGraphView:(CTGraphView*)inGraphView;
- (void)didUpdateGraphView:(CTGraphView*)inGraphView;

@end
