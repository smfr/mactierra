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

static const double kMillion = 1.0e6;

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
@property (readonly) NSString* xAxisLabel;

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
    else if (mapped <= 0.4)
    {
        max = 0.4 * power;
        *outNumDivisions = 4;
    }
    else if (mapped <= 0.5)
    {
        max = 0.5 * power;
        *outNumDivisions = 5;
    }
    else if (mapped <= 0.8)
    {
        max = 0.8 * power;
        *outNumDivisions = 4;
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

- (NSString*)xAxisLabel
{
    // for subclassers
    return nil;
}

- (void)clear
{
    // break retain cycle
    graphView.dataSource = nil;
    graphView.delegate = nil;
}

// CTGraphViewDelegate methods
- (void)willUpdateGraphView:(CTGraphView*)inGraphView
{
}

- (void)didUpdateGraphView:(CTGraphView*)inGraphView
{
}

@end

#pragma mark -

@interface MTTimelineGraphAdapter : MTGraphAdapter
@end

@implementation MTTimelineGraphAdapter

- (NSString*)xAxisLabel
{
    return NSLocalizedString(@"TimeAxisLabel", @"Time");
}

- (void)setupGraph
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTScatterPlotView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    graphView.showXTickMarks = NO;
    graphView.showTitle = NO;
    graphView.showYLabel = NO;
    graphView.xLabel = [NSAttributedString attributedStringWithString:[self xAxisLabel] attributes:[MTGraphAdapter axisLabelAttributes]];
    graphView.showXLabel = YES;

    graphView.dataSource = self;        // retain cycle
    graphView.delegate = self;
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    SimpleDataLogger* logger = dynamic_cast<SimpleDataLogger*>(dataLogger);
    if (!logger) return;
    
    u_int32_t numDivisions;
    u_int64_t minInstructions = logger->minInstructions();
    u_int64_t maxInstructions = logger->maxInstructions();
    
    graphView.xMin = (double)minInstructions / kMillion;
    graphView.xMax = graphAxisMax(std::max((double)maxInstructions / kMillion, 1.0), &numDivisions);
    graphView.xScale = [graphView xMax] / numDivisions;
    
    double yMax = graphAxisMax(logger->maxDoubleValue(), &numDivisions);
    graphView.yMax = yMax;
    graphView.yScale = yMax / numDivisions;
    [graphView dataChanged];
}

@end

#pragma mark -

@interface MTPopulationSizeGraphAdapter : MTTimelineGraphAdapter
@end

@implementation MTPopulationSizeGraphAdapter

- (NSString*)xAxisLabel
{
    return NSLocalizedString(@"SlicerCyclesAxisLabel", @"Cycles");
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    SimpleDataLogger* logger = dynamic_cast<SimpleDataLogger*>(dataLogger);
    if (!logger) return;
    
    u_int32_t numDivisions;
    u_int64_t minCycles = logger->minSlicerCycles();
    u_int64_t maxCycles = logger->maxSlicerCycles();
    
    graphView.xMin = (double)minCycles;
    graphView.xMax = graphAxisMax(std::max((double)maxCycles, 1.0), &numDivisions);
    graphView.xScale = [graphView xMax] / numDivisions;
    
    double yMax = graphAxisMax(logger->maxDoubleValue(), &numDivisions);
    graphView.yMax = yMax;
    graphView.yScale = yMax / numDivisions;
    [graphView dataChanged];
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    PopulationSizeLogger* popSizeLogger = dynamic_cast<PopulationSizeLogger*>(dataLogger);
    if (popSizeLogger && index < popSizeLogger->dataCount())
    {
        PopulationSizeLogger::data_tuple curTuple = popSizeLogger->data()[index];
        *(*point) = NSMakePoint((double)PopulationSizeLogger::getSlicerCycles(curTuple), PopulationSizeLogger::getData(curTuple));
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTCreatureSizeGraphAdapter : MTTimelineGraphAdapter
@end

@implementation MTCreatureSizeGraphAdapter

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    MeanCreatureSizeLogger* creatureSizeLogger = dynamic_cast<MeanCreatureSizeLogger*>(dataLogger);
    if (creatureSizeLogger && index < creatureSizeLogger->dataCount())
    {
        MeanCreatureSizeLogger::data_tuple curTuple = creatureSizeLogger->data()[index];
        *(*point) = NSMakePoint((double)MeanCreatureSizeLogger::getInstructions(curTuple) / kMillion, MeanCreatureSizeLogger::getData(curTuple));
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTMaxFitnessGraphAdapter : MTTimelineGraphAdapter
@end

@implementation MTMaxFitnessGraphAdapter

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    MaxFitnessDataLogger* fitnessLogger = dynamic_cast<MaxFitnessDataLogger*>(dataLogger);
    if (fitnessLogger && index < fitnessLogger->dataCount())
    {
        MaxFitnessDataLogger::data_tuple curTuple = fitnessLogger->data()[index];
        *(*point) = NSMakePoint((double)MaxFitnessDataLogger::getInstructions(curTuple) / kMillion, MaxFitnessDataLogger::getData(curTuple));
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTHistogramGraphAdapter : MTGraphAdapter
@end

@implementation MTHistogramGraphAdapter : MTGraphAdapter

- (void)setupGraph
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTHistogramView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    graphView.showXTickMarks = NO;
    graphView.showTitle = NO;
    graphView.showYLabel = NO;
    graphView.xLabel = [NSAttributedString attributedStringWithString:[self xAxisLabel] attributes:[MTGraphAdapter axisLabelAttributes]];

    graphView.dataSource = self;       // retain cycle
    graphView.delegate = self;
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    HistogramDataLogger* histogramLogger = dynamic_cast<HistogramDataLogger*>(dataLogger);
    if (!histogramLogger)
        return;

    MacTierra::World* theWorld = inWorldController.world;
    histogramLogger->collectData(MacTierra::DataLogger::kCollectionAdHoc, theWorld->timeSlicer().instructionsExecuted(), theWorld->timeSlicer().cycleCount(), theWorld);
    
    [(CTHistogramView*)graphView setNumberOfBuckets:std::max(histogramLogger->dataCount(), 1U)];

    u_int32_t numDivisions;
    double yMax = graphAxisMax(histogramLogger->maxFrequency(), &numDivisions);
    graphView.yMax = yMax;
    graphView.yScale = yMax / numDivisions;
    [graphView dataChanged];
}

@end

#pragma mark -

@interface MTGenotypeFrequencyGraphAdapter : MTHistogramGraphAdapter
@end

@implementation MTGenotypeFrequencyGraphAdapter

- (NSString*)xAxisLabel
{
    return NSLocalizedString(@"GenotypesAxisLabel", @"Genotypes");
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

@interface MTSizeHistorgramGraphAdapter : MTHistogramGraphAdapter
@end

@implementation MTSizeHistorgramGraphAdapter

- (NSString*)xAxisLabel
{
    return NSLocalizedString(@"SizeAxisLabel", @"Genotypes");
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
    [mGraphAdaptors makeObjectsPerformSelector:@selector(clear)];
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
    [mGraphAdaptors makeObjectsPerformSelector:@selector(clear)];
    [mGraphAdaptors release];
    mGraphAdaptors = nil;

    NSMutableArray*     adaptors = [NSMutableArray array];
    
    const WorldDataCollectors* dataCollectors = mWorldController.dataCollectors;
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
        [inNewAdaptor updateGraph:mWorldController];
    }
}

- (void)setCurrentGraphIndex:(NSInteger)inIndex
{
    currentGraphIndex = inIndex;
    
    if (currentGraphIndex < [mGraphAdaptors count])
        [self switchToAdaptor:[mGraphAdaptors objectAtIndex:currentGraphIndex]];
}


@end
