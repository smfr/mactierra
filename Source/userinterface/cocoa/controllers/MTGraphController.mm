//
//  MTGraphController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTGraphController.h"

#import <algorithm>

#import <GraphX/CTScatterPlotView.h>
#import <GraphX/CTHistogramView.h>

#import "NSViewAdditions.h"

#import "MT_DataCollectors.h"

#import "MTWorldController.h"

@interface MTGraphController(Private)

- (void)setupLineGraph;
- (void)setupBarGraph;

@end

#pragma mark -


@implementation MTGraphController

- (void)awakeFromNib
{
    [self setupLineGraph];
}

- (void)dealloc
{
    [mDataValue release];
    [super dealloc];
}

- (NSArray*)availableGraphTypes
{
    return mGraphTypes;
}

#pragma mark -

- (void)setupLineGraph
{
    CTScatterPlotView* graphView = [[CTScatterPlotView alloc] initWithFrame:[mGraphContainerView bounds]];
    [graphView setDataSource:self];

    [mGraphContainerView addFullSubview:graphView replaceExisting:YES fill:YES];
    [graphView release];
}

- (void)setupBarGraph
{
    CTHistogramView* graphView = [[CTHistogramView alloc] initWithFrame:[mGraphContainerView bounds]];
    [graphView setDataSource:self];

    [mGraphContainerView addFullSubview:graphView replaceExisting:YES fill:YES];
    [graphView release];
}

- (void)updateGraph
{
    // FIXME: assume line graph for now
    CTGraphView*    graphView = (CTGraphView*)[mGraphContainerView firstSubview];

    MacTierra::PopulationSizeLogger* popSizeLogger = mWorldController.popSizeLogger;
    if (!popSizeLogger) return;

    std::vector<u_int32_t>* dataPtr = new std::vector<u_int32_t>(popSizeLogger->data());

    [graphView setXMin:0.0];
    [graphView setXMax:std::max((double)dataPtr->size(), 1.0)];

    // FIXME: compute
    [graphView setYMax:3000.0];
    [graphView setYScale:500.0];

    mCollectionInterval = popSizeLogger->lastCollectionTime() / dataPtr->size();
    
    [mDataValue release];
    mDataValue = [[NSValue valueWithPointer:dataPtr] retain];
}

#pragma mark -

// data source methods

// histogram
 - (float)frequencyForBucketWithLowerBound:(float)lowerBound andUpperLimit:(float)upperLimit
{
    return 0.0f;
}

// scatter plot
- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    if (mDataValue)
    {
        std::vector<u_int32_t>* dataPtr = (std::vector<u_int32_t>*)[mDataValue pointerValue];

        if (index < (*dataPtr).size())
            *(*point) = NSMakePoint(index, (*dataPtr)[index]);
        else
            *point = NULL;
    }
    else
    {
        *point = NULL;
    }
}



@end
