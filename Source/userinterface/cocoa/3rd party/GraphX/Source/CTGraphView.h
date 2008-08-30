//
//  CTGraphView.h
//
//  Created by Chad Weider on Fri May 14 2004.
//  Copyright (c) 2005 Cotingent. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface CTGraphView : NSView
  {
  float gMin, gMax, gScale;		//Specifies the minimum/maximum values for X Axis
								// xscale used to determine location of Vertical Gridlines & X Axix tick marks
	
  float hMin, hMax, hScale;		//Specifies the minimum/maximum values for Y Axis
								// yscale used to determine location of Horizontal Gridlines & Y Axix tick marks
  
  NSColorList *graphColors;		//List of all the colors that CTGraphView will use when Drawing itself

  NSAttributedString *xlabel, *ylabel, *title;  //String to be used as label for corresponding
  
  
  bool drawXAxisFlag , drawYAxisFlag     ,	//Flags to turn on/off different components of CTGraphView
       drawXTickMarks, drawYTickMarks    ,
	   drawXNumsFlag , drawYNumsFlag     ,
	   drawXGridFlag , drawYGridFlag     ,
	   drawXLabelFlag, drawYLabelFlag    ,
	   drawTitleFlag , drawBackgroundFlag;
  
  
  float labelPadding;		//padding(space between)layers in x and y Axis layers and Graph
  float titlePadding;		//padding(space between) Title and Graph
  
  unsigned xMinorLineCount;
  unsigned yMinorLineCount;
  
  float axisLineWidth;		//width constant for lines on x and y Axis
  float majorLineWidth;		//width of gridlines - applies to both x and y gridlines
  float minorLineWidth;		//width of gridlines - applies to both x and y gridlines
  
  float lineDashPattern[2];	//dashing pattern used by axis that are out of bounds
  }


- (float)titleHeight ;   //Gives amount of space used by Title(at the top of the graph) - if drawTitleFlag is NO then it will give a height of 0
- (float)xLabelHeight;   //Gives amount of space used by XAxis Label size depends on if flag is set
- (float)yLabelWidth ;   //Gives amount of space used by YAxis Label size depends on if flag is set


- (void)drawTitle :(NSRect)rect;	//Will draw title at the top of the Graph
- (void)drawXLabel:(NSRect)rect;	//Will draw X Axis Label - if Flag is set
- (void)drawYLabel:(NSRect)rect;	//Will draw Y Axis Label - if Flag is set

- (void)drawBackground:(NSRect)rect;//Fills the Graph Region

- (void)drawXGrid:(NSRect)rect;		//Will draw Vertical Gridlines
- (void)drawYGrid:(NSRect)rect;		//Will draw Horizontal Gridlines

- (void)drawXAxis:(NSRect)rect;		//Will draw X Axis line, tick marks, numbers
- (void)drawYAxis:(NSRect)rect;		//Will draw Y Axis line, tick marks, numbers


- (NSData *)graphImage;



//Customization Methods
- (void)setXMin:  (float)bound;
- (void)setXMax:  (float)bound;
- (void)setXScale:(float)bound;
- (void)setYMinorLineCount:(unsigned)count;

- (void)setYMin:  (float)bound;
- (void)setYMax:  (float)bound;
- (void)setYScale:(float)bound;
- (void)setYMinorLineCount:(unsigned)count;

- (void)setShowTitle :(bool)state;

- (void)setShowXLabel:(bool)state;
- (void)setShowXAxis :(bool)state;
- (void)setShowXGrid :(bool)state;
- (void)setShowXTickMarks:(bool)state;

- (void)setShowYLabel:(bool)state;
- (void)setShowYAxis :(bool)state;
- (void)setShowYGrid :(bool)state;
- (void)setShowYTickMarks:(bool)state;

- (void)setShowBackground:(bool)state;

- (void)setXAxisColor:(NSColor *)color;
- (void)setXGridColor:(NSColor *)color;

- (void)setYAxisColor:(NSColor *)color;
- (void)setYGridColor:(NSColor *)color;

- (void)setBackgroundColor:(NSColor *)color;

- (void)setTitle:(NSAttributedString *)string;
- (void)setXLabel:(NSAttributedString *)string;
- (void)setYLabel:(NSAttributedString *)string;
- (NSAttributedString *)title;
- (NSAttributedString *)xLabel;
- (NSAttributedString *)yLabel;


//State Methods
- (float)xMin;
- (float)xMax;
- (float)xScale;
- (unsigned)xMinorLineCount;

- (float)yMin;
- (float)yMax;
- (float)yScale;
- (unsigned)yMinorLineCount;

- (bool)showTitle;

- (bool)showXLabel;
- (bool)showXAxis ;
- (bool)showXGrid ;
- (bool)showXTickMarks;

- (bool)showYLabel;
- (bool)showYAxis ;
- (bool)showYGrid ;
- (bool)showYTickMarks;

- (bool)showBackground;

- (NSColor *)xAxisColor;
- (NSColor *)xGridColor;

- (NSColor *)yAxisColor;
- (NSColor *)yGridColor;

- (NSColor *)backgroundColor;

@end
