//
//  MTGraphController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSArrayAdditions.h"
#import "NSAttributedStringAdditions.h"

#import "MTGraphController.h"

#import <algorithm>

#import <GraphX/CTScatterPlotView.h>
#import <GraphX/CTHistogramView.h>

#import "NSViewAdditions.h"

#import "MT_DataCollectors.h"
#import "MT_TimeSlicer.h"
#import "MT_World.h"

#import "MTGenotypeImageView.h"
#import "MTCreature.h"
#import "MTInventoryGenotype.h"
#import "MTWorldController.h"
#import "MTWorldDataCollection.h"

static const double kMillion = 1.0e6;

@class MTGraphAdapter;

@interface MTGraphController(Private)

- (void)startObservingGraphs;
- (void)stopObservingGraphs;

- (void)setupGraphAdaptors;
- (MTGraphAdapter*)selectedGraphAdaptor;
- (void)switchToAdaptor:(MTGraphAdapter*)inNewAdaptor;

@end

#pragma mark -

@interface MTGraphAdapter : NSObject
{
    MTGraphController*          mController;    // not owned (it owns us)
    MacTierra::DataLogger*      dataLogger;     // owned by the world controller
    CTGraphView*                graphView;

    NSString*                   identifier;
    NSString*                   localizedName;
    
    NSViewController*           auxiliaryViewController;
}

@property (copy) NSString* identifier;
@property (copy) NSString* localizedName;

@property (retain) CTGraphView* graphView;
@property (assign) MacTierra::DataLogger* dataLogger;
@property (readonly) NSString* xAxisLabel;

@property (retain) NSViewController* auxiliaryViewController;

+ (NSDictionary*)axisLabelAttributes;

+ (id)graphAdaptorWithGraphController:(MTGraphController*)inController;

- (id)initWithGraphController:(MTGraphController*)inController;
- (void)setupGraphView;
- (void)setupAuxiliaryView;
- (void)updateGraph:(MTWorldController*)inWorldController;
- (void)dataLoggerChanged;

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
@synthesize auxiliaryViewController;

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
        [self setupAuxiliaryView];
    }
    return self;
}

- (void)dealloc
{
    self.graphView = nil;
    self.auxiliaryViewController = nil;
    [super dealloc];
}

- (void)setupGraphView
{
    // for subclassers
}

- (void)setupAuxiliaryView
{
    // for subclassers
}

- (void)updateGraph:(MTWorldController*)inWorldController
{
    // for subclassers
}

- (void)dataLoggerChanged
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

- (NSInteger)numberOfSeries
{
    return 1;
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index inSeries:(NSInteger)inSeries
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

- (NSInteger)numberOfSeries
{
    return 1;
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index inSeries:(NSInteger)inSeries
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

- (NSInteger)numberOfSeries
{
    return 1;
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index inSeries:(NSInteger)inSeries
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

@implementation TwoGenotypesViewController

- (MTGenotypeImageView*)firstGenotypeImageView
{
    return firstGenotypeImageView;
}

- (MTGenotypeImageView*)secondGenotypeImageView
{
    return secondGenotypeImageView;
}

- (void)setupBindings
{
    // For some reason, binding doesn't work
    [firstGenotypeImageView addObserver:self 
                             forKeyPath:@"genotype"
                                options:0
                                context:NULL];

    [secondGenotypeImageView addObserver:self 
                             forKeyPath:@"genotype"
                                options:0
                                context:NULL];
}

- (void)clearBindings
{
    [firstGenotypeImageView removeObserver:self forKeyPath:@"genotype"];
    [secondGenotypeImageView removeObserver:self forKeyPath:@"genotype"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"genotype"])
    {
        if (object == firstGenotypeImageView)
            [[self representedObject] setValue:firstGenotypeImageView.genotype forKeyPath:@"firstGenotype"];
        else if (object == secondGenotypeImageView)
            [[self representedObject] setValue:secondGenotypeImageView.genotype forKeyPath:@"secondGenotype"];
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end

@interface MTTwoGenotypesFrequencyGraphAdapter : MTCyclesGraphAdapter
{
    MTInventoryGenotype* firstGenotype;
    MTInventoryGenotype* secondGenotype;
}

@property (retain) MTInventoryGenotype* firstGenotype;
@property (retain) MTInventoryGenotype* secondGenotype;

@end

static const NSInteger kFirstGenotypeImageViewTag = 1001;
static const NSInteger kSecondGenotypeImageViewTag = 1002;

@implementation MTTwoGenotypesFrequencyGraphAdapter

@synthesize firstGenotype;
@synthesize secondGenotype;

+ (NSString*)identifier
{
    return @"two_genotypes_frequency";
}

+ (NSString*)localizedName
{
    return NSLocalizedString(@"TwoGenotypesFrequency", @"");
}

- (void)setupGraphView
{
    [super setupGraphView];
    
    CTScatterPlotView* scatterPlotView = (CTScatterPlotView*)graphView;
    scatterPlotView.showFill = NO;
    [scatterPlotView setCurveColor:[NSColor blueColor] forSeries:0];
    [scatterPlotView setCurveColor:[NSColor redColor ] forSeries:1];
}

- (void)clear
{
    [(TwoGenotypesViewController*)auxiliaryViewController clearBindings];
    auxiliaryViewController.representedObject = nil;

    self.firstGenotype = nil;
    self.secondGenotype = nil;

    [super clear];
}

- (void)setupAuxiliaryView
{
    TwoGenotypesViewController* viewController = [[[TwoGenotypesViewController alloc] initWithNibName:@"TwoGenotypesAuxiliaryView" bundle:nil] autorelease];
    [viewController loadView];
    self.auxiliaryViewController = viewController;
    auxiliaryViewController.representedObject = self;
    
    [viewController setupBindings];
    [viewController firstGenotypeImageView].worldController = mController.worldController;
    [viewController secondGenotypeImageView].worldController = mController.worldController;
}

- (void)dataLoggerChanged
{
    TwoGenotypesFrequencyLogger* genotypesLogger = dynamic_cast<TwoGenotypesFrequencyLogger*>(dataLogger);
    if (!genotypesLogger)
        return;

    TwoGenotypesViewController* viewController = (TwoGenotypesViewController*)auxiliaryViewController;
    
    if (genotypesLogger->firstGenotype())
    {
        self.firstGenotype = [[[MTInventoryGenotype alloc] initWithGenotype:genotypesLogger->firstGenotype()] autorelease];
        // Ideally the image views would be bound, and this would "just work". Alas, it doesn't.
        [viewController firstGenotypeImageView].genotype = self.firstGenotype;
    }

    if (genotypesLogger->secondGenotype())
    {
        self.secondGenotype = [[[MTInventoryGenotype alloc] initWithGenotype:genotypesLogger->secondGenotype()] autorelease];
        // Ideally the image views would be bound, and this would "just work". Alas, it doesn't.
        [viewController secondGenotypeImageView].genotype = self.secondGenotype;
    }
}

- (void)setFirstGenotype:(MTInventoryGenotype*)inGenotype
{
    if (inGenotype != firstGenotype)
    {
        [self willChangeValueForKey:@"firstGenotype"];
        [firstGenotype release];
        firstGenotype = [inGenotype retain];
        
        if (dataLogger)
        {
            TwoGenotypesFrequencyLogger* genotypesLogger = dynamic_cast<TwoGenotypesFrequencyLogger*>(dataLogger);
            genotypesLogger->setFirstGenotype(firstGenotype ? firstGenotype.genotype : NULL);
        }
        
        [self didChangeValueForKey:@"firstGenotype"];
    }
}

- (void)setSecondGenotype:(MTInventoryGenotype*)inGenotype
{
    if (inGenotype != secondGenotype)
    {
        [self willChangeValueForKey:@"secondGenotype"];
        [secondGenotype release];
        secondGenotype = [inGenotype retain];

        if (dataLogger)
        {
            TwoGenotypesFrequencyLogger* genotypesLogger = dynamic_cast<TwoGenotypesFrequencyLogger*>(dataLogger);
            genotypesLogger->setSecondGenotype(secondGenotype ? secondGenotype.genotype : NULL);
        }
        
        [self didChangeValueForKey:@"secondGenotype"];
    }
}

- (NSInteger)numberOfSeries
{
    return 2;
}

- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index inSeries:(NSInteger)inSeries
{
    TwoGenotypesFrequencyLogger* genotypesLogger = dynamic_cast<TwoGenotypesFrequencyLogger*>(dataLogger);
    if (genotypesLogger && index < genotypesLogger->dataCount())
    {
        TwoGenotypesFrequencyLogger::data_tuple curTuple = genotypesLogger->data()[index];
        u_int32_t frequency = (inSeries == 0) ? TwoGenotypesFrequencyLogger::getData(curTuple).first : TwoGenotypesFrequencyLogger::getData(curTuple).second;
        *(*point) = NSMakePoint((double)TwoGenotypesFrequencyLogger::getSlicerCycles(curTuple), frequency);
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

- (NSInteger)numberOfSeries
{
    return 1;
}

- (float)frequencyForBucket:(NSUInteger)index label:(NSString**)outLabel inSeries:(NSInteger)series
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

- (NSInteger)numberOfSeries
{
    return 1;
}

- (float)frequencyForBucket:(NSUInteger)index label:(NSString**)outLabel inSeries:(NSInteger)series
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

- (void)awakeFromNib
{
    [self setupGraphAdaptors];
    [self startObservingGraphs];
}

- (void)dealloc
{
    [graphs makeObjectsPerformSelector:@selector(clear)];
    self.graphs = nil;

    [super dealloc];
}

- (void)documentClosing
{
    [self stopObservingGraphs];
}

- (MTWorldController*)worldController
{
    return mWorldController;
}

#pragma mark -

- (void)setupGraphAdaptors
{
    [graphs makeObjectsPerformSelector:@selector(clear)];

    NSMutableArray* adaptors = [NSMutableArray array];
    
    [adaptors addObject:[MTPopulationSizeGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTCreatureSizeGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTMaxFitnessGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTTwoGenotypesFrequencyGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTGenotypeFrequencyGraphAdapter graphAdaptorWithGraphController:self]];
    [adaptors addObject:[MTSizeHistorgramGraphAdapter graphAdaptorWithGraphController:self]];

    self.graphs = adaptors;
    [self switchToAdaptor:[self selectedGraphAdaptor]];
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

        MTGraphAdapter* twoGenotypesGrapher = [self adaptorWithIdentifier:[MTTwoGenotypesFrequencyGraphAdapter identifier]];
        twoGenotypesGrapher.dataLogger = dataCollectors->twoGenotypesFrequencyLogger();

        MTGraphAdapter* genotypeFrequencyGrapher = [self adaptorWithIdentifier:[MTGenotypeFrequencyGraphAdapter identifier]];
        genotypeFrequencyGrapher.dataLogger = dataCollectors->genotypeFrequencyDataLogger();

        MTGraphAdapter* sizeHistogramGrapher = [self adaptorWithIdentifier:[MTSizeHistorgramGraphAdapter identifier]];
        sizeHistogramGrapher.dataLogger = dataCollectors->sizeHistogramDataLogger();

        [graphs makeObjectsPerformSelector:@selector(dataLoggerChanged) withObject:nil];
    }
    else
    {
        [graphs makeObjectsPerformSelector:@selector(setDataLogger:) withObject:nil];
    }
}

- (void)worldChanged
{
    [self updateGraphAdaptors];
}

- (MTGraphAdapter*)selectedGraphAdaptor
{
    return [[mGraphsArrayController selectedObjects] firstObject];
}

- (void)updateGraph
{
    [[self selectedGraphAdaptor] updateGraph:mWorldController];
}

- (void)switchToAdaptor:(MTGraphAdapter*)inNewAdaptor
{
    if (inNewAdaptor)
    {
        [mGraphContainerView addFullSubview:inNewAdaptor.graphView replaceExisting:YES fill:YES];
        
        NSView* adaptorAuxiliaryView = [inNewAdaptor.auxiliaryViewController view];
        if (adaptorAuxiliaryView)
            [mGraphAdditionsView addFullSubview:adaptorAuxiliaryView replaceExisting:YES fill:YES];
        else
            [mGraphAdditionsView removeAllSubviews];

        [inNewAdaptor updateGraph:mWorldController];
    }
}

- (void)startObservingGraphs
{
    [mGraphsArrayController addObserver:self
                             forKeyPath:@"selection"
                                options:0
                                context:NULL];
}

- (void)stopObservingGraphs
{
    [mGraphsArrayController removeObserver:self forKeyPath:@"selection"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selection"])
    {
        [self switchToAdaptor:[self selectedGraphAdaptor]];
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
