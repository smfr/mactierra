//
//  CTGraphView.h
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface CTGraphView : NSView
{
    float xMin, xMax, xScale;     //Specifies the minimum/maximum values for X Axis
                                // xscale used to determine location of Vertical Gridlines & X Axix tick marks

    float yMin, yMax, yScale;     //Specifies the minimum/maximum values for Y Axis
                                // yscale used to determine location of Horizontal Gridlines & Y Axix tick marks
  
    NSColorList* graphColors;     //List of all the colors that CTGraphView will use when Drawing itself

    NSAttributedString* xLabel;
    NSAttributedString* yLabel;
    NSAttributedString* title;
  
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
  
    float labelPadding;       //padding(space between)layers in x and y Axis layers and Graph
    float titlePadding;       //padding(space between) Title and Graph

    unsigned xMinorLineCount;
    unsigned yMinorLineCount;

    float axisLineWidth;      //width constant for lines on x and y Axis
    float majorLineWidth;     //width of gridlines - applies to both x and y gridlines
    float minorLineWidth;     //width of gridlines - applies to both x and y gridlines

    float lineDashPattern[2]; //dashing pattern used by axis that are out of bounds
}

- (NSData *)graphImage;


@property (assign) float xMin;
@property (assign) float xMax;
@property (assign) float xScale;
@property (assign) unsigned xMinorLineCount;

@property (assign) float yMin;
@property (assign) float yMax;
@property (assign) float yScale;
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

@property (retain) NSColor* xAxisColor;
@property (retain) NSColor* xGridColor;

@property (retain) NSColor* yAxisColor;
@property (retain) NSColor* yGridColor;

@property (retain) NSColor* backgroundColor;

@property (copy) NSAttributedString* title;
@property (copy) NSAttributedString* xLabel;
@property (copy) NSAttributedString* yLabel;


@end
