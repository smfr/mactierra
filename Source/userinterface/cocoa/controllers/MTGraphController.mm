//
//  MTGraphController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSAttributedStringAdditions.h"

#import "MTGraphController.h"

#import <algorithm>

#import <GraphX/CTScatterPlotView.h>
#import <GraphX/CTHistogramView.h>

#import "NSViewAdditions.h"

#import "MT_DataCollectors.h"
#import "MT_TimeSlicer.h"
#import "MT_World.h"

#import "MTWorldController.h"
#import "MTWorldDataCollection.h"

@interface MTGraphController(Private)

- (void)setupLineGraph;
- (void)setupBarGraph;

@end

#pragma mark -

@interface MTGraphAdapter : NSObject
{
    MTGraphController*          mController;    // not owned (it owns us)
    MacTierra::DataLogger*      dataLogger;     // owned by the world controller
    CTGraphView*                graphView;
}

@property (retain) CTGraphView* graphView;
@property (assign) MacTierra::DataLogger* dataLogger;

+ (NSDictionary*)axisLabelAttributes;

- (id)initWithGraphController:(MTGraphController*)inController dataLogger:(MacTierra::DataLogger*)inLogger;
- (void)setupGraph;
- (void)updateGraph:(MTWorldController*)inWorldController;

@end

#pragma mark -

static double graphAxisMax(double inMaxValue, u_int32_t* outNumDivisions)
{
    if (inMaxValue == 0.0)
    {
        *outNumDivisions = 5;
        return 1.0;
    }
    
    // map the value to between 0.1 and 1
    double dec = log10(inMaxValue);
    double power = pow(10.0, ceil(dec));
    double mapped = inMaxValue / power;
    
    double max;
    if (mapped <= 0.2)
    {
        max = 0.2 * power;
        *outNumDivisions = 4;
    }
    else if (mapped <= 0.5)
    {
        max = 0.5 * power;
        *outNumDivisions = 5;
    }
    else
    {
        max = 1.0 * power;
        *outNumDivisions = 5;
    }
    
    return max;
}

@implementation MTGraphAdapter

@synthesize dataLogger;
@synthesize graphView;

+ (NSDictionary*)axisLabelAttributes
{
    static NSDictionary* sLabelAttributes = nil;
    
    if (!sLabelAttributes)
    {
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSCenterTextAlignment];
    
        sLabelAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont fontWithName:@"Lucida Grande" size:11], NSFontAttributeName,
                                                        pStyle, NSParagraphStyleAttributeName,
                                                                nil] retain];
        [pStyle release];
    }
    return sLabelAttributes;
}

- (id)initWithGraphController:(MTGraphController*)inController dataLogger:(MacTierra::DataLogger*)inLogger
{
    if ((self = [super init]))
    {
        mController = inController;
        dataLogger = inLogger;
    }
    return self;
}

- (void)dealloc
{
    self.graphView = nil;
    [super dealloc];
}

- (void)setupGraph
{
    // for subclassers
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    // for subclassers
}

@end

#pragma mark -

@interface MTPopulationSizeGraphAdapter : MTGraphAdapter
@end

@implementation MTPopulationSizeGraphAdapter

- (void)setupGraph
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTScatterPlotView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    [graphView setShowXTickMarks:NO];
    [graphView setShowTitle:NO];
    [graphView setShowYLabel:NO];
    [graphView setXLabel:[NSAttributedString attributedStringWithString:NSLocalizedString(@"TimeAxisLabel", @"Time") attributes:[MTGraphAdapter axisLabelAttributes]]];
    [(CTScatterPlotView*)graphView setDataSource:self];
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    PopulationSizeLogger* popSizeLogger = dynamic_cast<PopulationSizeLogger*>(dataLogger);
    if (!popSizeLogger) return;

    [graphView setXMin:0.0];
    [graphView setXMax:std::max((double)popSizeLogger->dataCount(), 1.0)];

    u_int32_t numDivisions;
    double yMax = graphAxisMax(popSizeLogger->maxValue(), &numDivisions);
    [graphView setYMax:yMax];
    [graphView setYScale:yMax / numDivisions];
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    PopulationSizeLogger* popSizeLogger = dynamic_cast<PopulationSizeLogger*>(dataLogger);
    if (popSizeLogger && index < popSizeLogger->dataCount())
    {
        *(*point) = NSMakePoint(index, popSizeLogger->data()[index].second);
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTCreatureSizeGraphAdapter : MTGraphAdapter
@end

@implementation MTCreatureSizeGraphAdapter

- (void)setupGraph
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTScatterPlotView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    [graphView setShowXTickMarks:NO];
    [graphView setShowTitle:NO];
    [graphView setShowYLabel:NO];
    [graphView setXLabel:[NSAttributedString attributedStringWithString:NSLocalizedString(@"TimeAxisLabel", @"Time") attributes:[MTGraphAdapter axisLabelAttributes]]];
    [(CTScatterPlotView*)graphView setDataSource:self];
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    MeanCreatureSizeLogger* creatureSizeLogger = dynamic_cast<MeanCreatureSizeLogger*>(dataLogger);
    if (!creatureSizeLogger) return;

    [graphView setXMin:0.0];
    [graphView setXMax:std::max((double)creatureSizeLogger->dataCount(), 1.0)];

    u_int32_t numDivisions;
    double yMax = graphAxisMax(creatureSizeLogger->maxValue(), &numDivisions);
    [graphView setYMax:yMax];
    [graphView setYScale:yMax / numDivisions];
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    MeanCreatureSizeLogger* creatureSizeLogger = dynamic_cast<MeanCreatureSizeLogger*>(dataLogger);
    if (creatureSizeLogger && index < creatureSizeLogger->dataCount())
    {
        *(*point) = NSMakePoint(index, creatureSizeLogger->data()[index].second);
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTMaxFitnessGraphAdapter : MTGraphAdapter
@end

@implementation MTMaxFitnessGraphAdapter

- (void)setupGraph
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTScatterPlotView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    [graphView setShowXTickMarks:NO];
    [graphView setShowTitle:NO];
    [graphView setShowYLabel:NO];
    [graphView setXLabel:[NSAttributedString attributedStringWithString:NSLocalizedString(@"TimeAxisLabel", @"Time") attributes:[MTGraphAdapter axisLabelAttributes]]];
    [(CTScatterPlotView*)graphView setDataSource:self];
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    MaxFitnessDataLogger* fitnessLogger = dynamic_cast<MaxFitnessDataLogger*>(dataLogger);
    if (!fitnessLogger) return;

    [graphView setXMin:0.0];
    [graphView setXMax:std::max((double)fitnessLogger->dataCount(), 1.0)];

    u_int32_t numDivisions;
    double yMax = graphAxisMax(fitnessLogger->maxValue(), &numDivisions);
    [graphView setYMax:yMax];
    [graphView setYScale:yMax / numDivisions];
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    MaxFitnessDataLogger* fitnessLogger = dynamic_cast<MaxFitnessDataLogger*>(dataLogger);
    if (fitnessLogger && index < fitnessLogger->dataCount())
    {
        *(*point) = NSMakePoint(index, fitnessLogger->data()[index].second);
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTGenotypeFrequencyGraphAdapter : MTGraphAdapter
@end

@implementation MTGenotypeFrequencyGraphAdapter

- (void)setupGraph
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTHistogramView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    [graphView setShowXTickMarks:NO];
    [graphView setShowTitle:NO];
    [graphView setShowYLabel:NO];
    [graphView setXLabel:[NSAttributedString attributedStringWithString:NSLocalizedString(@"TimeAxisLabel", @"Time") attributes:[MTGraphAdapter axisLabelAttributes]]];
    [(CTHistogramView*)graphView setDataSource:self];
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    GenotypeFrequencyDataLogger* genotypeLogger = dynamic_cast<GenotypeFrequencyDataLogger*>(dataLogger);
    if (!genotypeLogger) return;

    MacTierra::World* theWorld = inWorldController.world;
    genotypeLogger->collectData(theWorld->timeSlicer().instructionsExecuted(), theWorld);
    
    [(CTHistogramView*)graphView setNumberOfBuckets:std::max(genotypeLogger->dataCount(), 1U)];

    u_int32_t numDivisions;
    double yMax = graphAxisMax(genotypeLogger->maxFrequency(), &numDivisions);
    [graphView setYMax:yMax];
    [graphView setYScale:yMax / numDivisions];
}

- (float)frequencyForBucket:(NSUInteger)index label:(NSString**)outLabel
{
    GenotypeFrequencyDataLogger* genotypeLogger = dynamic_cast<GenotypeFrequencyDataLogger*>(dataLogger);
    if (!genotypeLogger) return 0.0f;
    
    if (index >= genotypeLogger->dataCount())
        return 0.0f;

    *outLabel = [NSString stringWithUTF8String:genotypeLogger->data()[index].first.c_str()];
    u_int32_t datum = genotypeLogger->data()[index].second;
    return (float)datum;
}

@end

#pragma mark -

@interface MTSizeHistorgramGraphAdapter : MTGraphAdapter
@end

@implementation MTSizeHistorgramGraphAdapter

- (void)setupGraph
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTHistogramView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    [graphView setShowXTickMarks:NO];
    [graphView setShowTitle:NO];
    [graphView setShowYLabel:NO];
    [graphView setXLabel:[NSAttributedString attributedStringWithString:NSLocalizedString(@"TimeAxisLabel", @"Time") attributes:[MTGraphAdapter axisLabelAttributes]]];
    [(CTHistogramView*)graphView setDataSource:self];
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    SizeHistogramDataLogger* sizeLogger = dynamic_cast<SizeHistogramDataLogger*>(dataLogger);
    if (!sizeLogger) return;

    MacTierra::World* theWorld = inWorldController.world;
    sizeLogger->collectData(theWorld->timeSlicer().instructionsExecuted(), theWorld);
    
    [(CTHistogramView*)graphView setNumberOfBuckets:std::max(sizeLogger->dataCount(), 1U)];

    u_int32_t numDivisions;
    double yMax = graphAxisMax(sizeLogger->maxFrequency(), &numDivisions);
    [graphView setYMax:yMax];
    [graphView setYScale:yMax / numDivisions];
}

- (float)frequencyForBucket:(NSUInteger)index label:(NSString**)outLabel
{
    SizeHistogramDataLogger* sizeLogger = dynamic_cast<SizeHistogramDataLogger*>(dataLogger);
    if (!sizeLogger) return 0.0f;
    
    if (index >= sizeLogger->dataCount())
        return 0.0f;

    *outLabel = [NSString stringWithFormat:@"%d-%d", sizeLogger->data()[index].first.first, sizeLogger->data()[index].first.second];
    u_int32_t datum = sizeLogger->data()[index].second;
    return (float)datum;
}

@end

#pragma mark -

NSString* const kGraphLabelKey      = @"graph_label";
NSString* const kGraphTypeKey       = @"graph_type";
NSString* const kGraphAdaptorKey    = @"graph_adaptor";

@implementation MTGraphController

@synthesize currentGraphIndex;

- (void)awakeFromNib
{
    self.currentGraphIndex = 0;
}

- (void)dealloc
{
    [mGraphAdaptors release];
    [mGraphTypes release];
    [super dealloc];
}

- (NSArray*)availableGraphTypes
{
    // This array needs to match the data collector types
    return [NSArray arrayWithObjects:

        [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedString(@"PopulationSize", @""), kGraphLabelKey,
                                                       nil],
    
        [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString(@"MeanCreatureSize", @""), kGraphLabelKey,
                                                       nil],

        [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString(@"MaxFitness", @""), kGraphLabelKey,
                                                       nil],

        [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString(@"GenotypeFrequencies", @""), kGraphLabelKey,
                                                       nil],

        [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString(@"SizeHistgram", @""), kGraphLabelKey,
                                                       nil],

        nil];
}

#pragma mark -

- (void)setupGraphAdaptors
{
    [mGraphAdaptors release]; mGraphAdaptors = nil;

    NSMutableArray*     adaptors = [NSMutableArray array];
    
    WorldDataCollectors* dataCollectors = mWorldController.dataCollectors;
    if (dataCollectors)
    {
        {
            MTGraphAdapter* popSizeGrapher = [[MTPopulationSizeGraphAdapter alloc] initWithGraphController:self dataLogger:dataCollectors->populationSizeLogger()];
            [popSizeGrapher setupGraph];
            [adaptors addObject:popSizeGrapher];
            [popSizeGrapher release];
        }
        
        {
            MTGraphAdapter* creatureSizeGrapher = [[MTCreatureSizeGraphAdapter alloc] initWithGraphController:self dataLogger:dataCollectors->meanCreatureSizeLogger()];
            [creatureSizeGrapher setupGraph];
            [adaptors addObject:creatureSizeGrapher];
            [creatureSizeGrapher release];
        }

        {
            MTGraphAdapter* fitnessGrapher = [[MTMaxFitnessGraphAdapter alloc] initWithGraphController:self dataLogger:dataCollectors->maxFitnessDataLogger()];
            [fitnessGrapher setupGraph];
            [adaptors addObject:fitnessGrapher];
            [fitnessGrapher release];
        }
        
        {
            MTGraphAdapter* genotypeFrequencyGrapher = [[MTGenotypeFrequencyGraphAdapter alloc] initWithGraphController:self dataLogger:dataCollectors->genotypeFrequencyDataLogger()];
            [genotypeFrequencyGrapher setupGraph];
            [adaptors addObject:genotypeFrequencyGrapher];
            [genotypeFrequencyGrapher release];
        }

        {
            MTGraphAdapter* sizeHistogramGrapher = [[MTSizeHistorgramGraphAdapter alloc] initWithGraphController:self dataLogger:dataCollectors->sizeHistogramDataLogger()];
            [sizeHistogramGrapher setupGraph];
            [adaptors addObject:sizeHistogramGrapher];
            [sizeHistogramGrapher release];
        }
    }
    
    mGraphAdaptors = [adaptors retain];
}

- (void)worldChanged
{
    [self setupGraphAdaptors];
    self.currentGraphIndex = 0;
}

- (void)updateGraph
{
    [[mGraphAdaptors objectAtIndex:currentGraphIndex] updateGraph:mWorldController];
}

- (void)switchToAdaptor:(MTGraphAdapter*)inNewAdaptor
{
    if (inNewAdaptor)
    {
        [mGraphContainerView addFullSubview:[inNewAdaptor graphView] replaceExisting:YES fill:YES];
    }
}

- (void)setCurrentGraphIndex:(NSInteger)inIndex
{
    currentGraphIndex = inIndex;
    
    if (currentGraphIndex < [mGraphAdaptors count])
        [self switchToAdaptor:[mGraphAdaptors objectAtIndex:currentGraphIndex]];
}


@end
