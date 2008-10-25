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

- (void)setupGraphAdaptors;

@end

#pragma mark -

@interface MTGraphAdapter : NSObject
{
    MTGraphController*          mController;    // not owned (it owns us)
    MacTierra::DataLogger*      dataLogger;     // owned by the world controller
    CTGraphView*                graphView;

    NSString*                   identifier;
    NSString*                   localizedName;
}

@property (copy) NSString* identifier;
@property (copy) NSString* localizedName;

@property (retain) CTGraphView* graphView;
@property (assign) MacTierra::DataLogger* dataLogger;
@property (readonly) NSString* xAxisLabel;

+ (NSDictionary*)axisLabelAttributes;

+ (id)graphAdaptorWithGraphController:(MTGraphController*)inController;

- (id)initWithGraphController:(MTGraphController*)inController;
- (void)setupGraphView;
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
@synthesize identifier;
@synthesize localizedName;

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

+ (NSString*)identifier
{
    [NSException exceptionWithName:NSInvalidArgumentException 
                    reason:@"MTGraphAdapter subclasses should override +identifier"
                    userInfo:nil];
    return @"";
}

+ (NSString*)localizedName
{
    [NSException exceptionWithName:NSInvalidArgumentException 
                    reason:@"MTGraphAdapter subclasses should override +localizedName"
                    userInfo:nil];
    return @"";
}

+ (id)graphAdaptorWithGraphController:(MTGraphController*)inController
{
    return [[[[self class] alloc] initWithGraphController:inController] autorelease];
}

- (id)initWithGraphController:(MTGraphController*)inController
{
    if ((self = [super init]))
    {
        mController = inController;
        self.identifier = [[self class] identifier];
        self.localizedName = [[self class] localizedName];
        [self setupGraphView];
    }
    return self;
}

- (void)dealloc
{
    self.graphView = nil;
    [super dealloc];
}

- (void)setupGraphView
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

- (void)setupGraphView
{
    NSAssert(!graphView, @"Should not have created graph view yet");
    
    self.graphView = [[[CTScatterPlotView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
    graphView.showXTickMarks = YES;
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

@interface MTCyclesGraphAdapter : MTGraphAdapter
@end

@implementation MTCyclesGraphAdapter

- (NSString*)xAxisLabel
{
    return NSLocalizedString(@"SlicerCyclesAxisLabel", @"Cycles");
}

- (void)setupGraphView
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

@end

#pragma mark -

@interface MTPopulationSizeGraphAdapter : MTCyclesGraphAdapter
@end

@implementation MTPopulationSizeGraphAdapter

+ (NSString*)identifier
{
    return @"population_size_timeline";
}

+ (NSString*)localizedName
{
    return NSLocalizedString(@"PopulationSize", @"");
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

@interface MTCreatureSizeGraphAdapter : MTCyclesGraphAdapter
@end

@implementation MTCreatureSizeGraphAdapter

+ (NSString*)identifier
{
    return @"creature_size_timeline";
}

+ (NSString*)localizedName
{
    return NSLocalizedString(@"MeanCreatureSize", @"");
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    MeanCreatureSizeLogger* creatureSizeLogger = dynamic_cast<MeanCreatureSizeLogger*>(dataLogger);
    if (creatureSizeLogger && index < creatureSizeLogger->dataCount())
    {
        MeanCreatureSizeLogger::data_tuple curTuple = creatureSizeLogger->data()[index];
        *(*point) = NSMakePoint((double)MeanCreatureSizeLogger::getSlicerCycles(curTuple), MeanCreatureSizeLogger::getData(curTuple));
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTMaxFitnessGraphAdapter : MTCyclesGraphAdapter
@end

@implementation MTMaxFitnessGraphAdapter

+ (NSString*)identifier
{
    return @"max_fitness_timeline";
}

+ (NSString*)localizedName
{
    return NSLocalizedString(@"MaxFitness", @"");
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
    MaxFitnessDataLogger* fitnessLogger = dynamic_cast<MaxFitnessDataLogger*>(dataLogger);
    if (fitnessLogger && index < fitnessLogger->dataCount())
    {
        MaxFitnessDataLogger::data_tuple curTuple = fitnessLogger->data()[index];
        *(*point) = NSMakePoint((double)MaxFitnessDataLogger::getSlicerCycles(curTuple), MaxFitnessDataLogger::getData(curTuple));
        return;
    }
    
    *point = NULL;
}

@end

#pragma mark -

@interface MTHistogramGraphAdapter : MTGraphAdapter
@end

@implementation MTHistogramGraphAdapter : MTGraphAdapter

- (void)setupGraphView
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

+ (NSString*)identifier
{
    return @"genotype_frequency_histogram";
}

+ (NSString*)localizedName
{
    return NSLocalizedString(@"GenotypeFrequencies", @"");
}

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

+ (NSString*)identifier
{
    return @"size_frequency_histogram";
}

+ (NSString*)localizedName
{
    return NSLocalizedString(@"SizeHistgram", @"");
}

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

@synthesize graphs;
@synthesize currentGraphIndex;

- (void)awakeFromNib
{
    self.currentGraphIndex = 0;
    [self setupGraphAdaptors];
}

- (void)dealloc
{
    [graphs makeObjectsPerformSelector:@selector(clear)];
    self.graphs = nil;

    [super dealloc];
}

#pragma mark -

- (void)setupGraphAdaptors
{
    [graphs makeObjectsPerformSelector:@selector(clear)];

    NSMutableArray* adaptors = [NSMutableArray array];
    
    [adaptors addObject:[MTPopulationSizeGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTCreatureSizeGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTMaxFitnessGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTGenotypeFrequencyGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTSizeHistorgramGraphAdapter graphAdaptorWithGraphController:self]];

    self.graphs = adaptors;
}

- (MTGraphAdapter*)adaptorWithIdentifier:(NSString*)inIdentifier
{
    // Slow linear search. We could put them in a dict, but not worth it.
    for (MTGraphAdapter* curAdaptor in graphs)
    {
        if ([curAdaptor.identifier isEqualToString:inIdentifier])
            return curAdaptor;
    }

    return nil;
}

- (void)updateGraphAdaptors
{
    const WorldDataCollectors* dataCollectors = mWorldController.dataCollectors;
    if (dataCollectors)
    {
        MTGraphAdapter* popSizeGrapher = [self adaptorWithIdentifier:[MTPopulationSizeGraphAdapter identifier]];
        popSizeGrapher.dataLogger = dataCollectors->populationSizeLogger();
        
        MTGraphAdapter* creatureSizeGrapher = [self adaptorWithIdentifier:[MTCreatureSizeGraphAdapter identifier]];
        creatureSizeGrapher.dataLogger = dataCollectors->meanCreatureSizeLogger();

        MTGraphAdapter* fitnessGrapher = [self adaptorWithIdentifier:[MTMaxFitnessGraphAdapter identifier]];
        fitnessGrapher.dataLogger = dataCollectors->maxFitnessDataLogger();

        MTGraphAdapter* genotypeFrequencyGrapher = [self adaptorWithIdentifier:[MTGenotypeFrequencyGraphAdapter identifier]];
        genotypeFrequencyGrapher.dataLogger = dataCollectors->genotypeFrequencyDataLogger();

        MTGraphAdapter* sizeHistogramGrapher = [self adaptorWithIdentifier:[MTSizeHistorgramGraphAdapter identifier]];
        sizeHistogramGrapher.dataLogger = dataCollectors->sizeHistogramDataLogger();
    }
    else
    {
        [graphs makeObjectsPerformSelector:@selector(setDataLogger:) withObject:nil];
    }
}

- (void)worldChanged
{
    [self updateGraphAdaptors];
    self.currentGraphIndex = 0;
}

- (void)updateGraph
{
    [[graphs objectAtIndex:currentGraphIndex] updateGraph:mWorldController];
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
    
    if (currentGraphIndex < [graphs count])
        [self switchToAdaptor:[graphs objectAtIndex:currentGraphIndex]];
}


@end
