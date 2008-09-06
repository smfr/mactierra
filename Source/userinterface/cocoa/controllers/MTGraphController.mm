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

#import "MTWorldController.h"

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
- (void)updateGraph;

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

- (void)updateGraph
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

- (void)updateGraph
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    MacTierra::PopulationSizeLogger* popSizeLogger = dynamic_cast<MacTierra::PopulationSizeLogger*>(dataLogger);
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
    MacTierra::PopulationSizeLogger* popSizeLogger = dynamic_cast<MacTierra::PopulationSizeLogger*>(dataLogger);
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

- (void)updateGraph
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    MacTierra::MeanCreatureSizeLogger* creatureSizeLogger = dynamic_cast<MacTierra::MeanCreatureSizeLogger*>(dataLogger);
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
    MacTierra::MeanCreatureSizeLogger* creatureSizeLogger = dynamic_cast<MacTierra::MeanCreatureSizeLogger*>(dataLogger);
    if (creatureSizeLogger && index < creatureSizeLogger->dataCount())
    {
        *(*point) = NSMakePoint(index, creatureSizeLogger->data()[index].second);
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

- (void)updateGraph
{
    // FIXME: this sucks, because the engine will have to be locked for the whole graph drawing process

    MacTierra::GenotypeFrequencyDataLogger* genotypeLogger = dynamic_cast<MacTierra::GenotypeFrequencyDataLogger*>(dataLogger);
    if (!genotypeLogger) return;

    [graphView setXMin:0.0];
    [graphView setXMax:std::max((double)genotypeLogger->dataCount(), 1.0)];
    [(CTHistogramView*)graphView setBucketWidth:1.0];     // fake buckets

    u_int32_t numDivisions;
    double yMax = graphAxisMax(genotypeLogger->maxFrequency(), &numDivisions);
    [graphView setYMax:yMax];
    [graphView setYScale:yMax / numDivisions];
}

- (float)frequencyForBucketWithLowerBound:(float)lowerBound andUpperLimit:(float)upperLimit
{
    u_int32_t index = (u_int32_t)floor(lowerBound);

    MacTierra::GenotypeFrequencyDataLogger* genotypeLogger = dynamic_cast<MacTierra::GenotypeFrequencyDataLogger*>(dataLogger);
    if (!genotypeLogger) return 0.0f;
    
    if (index >= genotypeLogger->dataCount())
        return 0.0f;

    u_int32_t datum = genotypeLogger->data()[index].second;
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
    return [NSArray arrayWithObjects:

        [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedString(@"PopulationSize", @""), kGraphLabelKey,
                                                       nil],
    
        [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString(@"MeanCreatureSize", @""), kGraphLabelKey,
                                                       nil],

        [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString(@"GenotypeFrequencies", @""), kGraphLabelKey,
                                                       nil],

        nil];
}

#pragma mark -

- (void)setupGraphAdaptors
{
    [mGraphAdaptors release]; mGraphAdaptors = nil;

    NSMutableArray*     adaptors = [NSMutableArray array];
    
    if (mWorldController.popSizeLogger)
    {
        MTGraphAdapter* popSizeGrapher = [[MTPopulationSizeGraphAdapter alloc] initWithGraphController:self dataLogger:mWorldController.popSizeLogger];
        [popSizeGrapher setupGraph];
        [adaptors addObject:popSizeGrapher];
        [popSizeGrapher release];
    }
    
    if (mWorldController.meanSizeLogger)
    {
        MTGraphAdapter* creatureSizeGrapher = [[MTCreatureSizeGraphAdapter alloc] initWithGraphController:self dataLogger:mWorldController.meanSizeLogger];
        [creatureSizeGrapher setupGraph];
        [adaptors addObject:creatureSizeGrapher];
        [creatureSizeGrapher release];
    }
    
    if (mWorldController.genotypeFrequencyLogger)
    {
        MTGraphAdapter* genotypeFrequencyGrapher = [[MTGenotypeFrequencyGraphAdapter alloc] initWithGraphController:self dataLogger:mWorldController.genotypeFrequencyLogger];
        [genotypeFrequencyGrapher setupGraph];
        [adaptors addObject:genotypeFrequencyGrapher];
        [genotypeFrequencyGrapher release];
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
    [[mGraphAdaptors objectAtIndex:currentGraphIndex] updateGraph];
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
    
    [self switchToAdaptor:[mGraphAdaptors objectAtIndex:currentGraphIndex]];
}


@end
