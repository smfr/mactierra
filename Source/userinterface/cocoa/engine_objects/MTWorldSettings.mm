//
//  MTWorldSettings.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTWorldSettings.h"

@interface MTWorldSettings(Private)

- (NSString*)keyForLevel:(EMutationRate)inLevel;
- (double)defaultRateForType:(NSString*)inType level:(EMutationRate)inLevel;
- (void)setInitialLevels;

- (void)updateCosmicMutationLevel;
- (void)updateFlawLevel;
- (void)updateCopyErrorLevel;


@end

#pragma mark -

@implementation MTWorldSettings

@synthesize soupSize;
@synthesize mutationDefaults;
@synthesize flawLevel;
@synthesize cosmicMutationLevel;
@synthesize copyErrorLevel;

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObject:@"flawRate"]
                                triggerChangeNotificationsForDependentKey:@"meanFlawInterval"];

    [self setKeys:[NSArray arrayWithObject:@"copyErrorRate"]
                                triggerChangeNotificationsForDependentKey:@"meanCopyErrorInterval"];

/*
    [self setKeys:[NSArray arrayWithObject:@"cosmicRate"]
                                triggerChangeNotificationsForDependentKey:@"meanCosmicTimeInterval"];
    [self setKeys:[NSArray arrayWithObject:@"meanCosmicTimeInterval"]
                                triggerChangeNotificationsForDependentKey:@"cosmicRate"];
*/
    [self setKeys:[NSArray arrayWithObject:@"soupSize"]
                                triggerChangeNotificationsForDependentKey:@"meanCosmicTimeInterval"];
}


- (id)initWithSettings:(const MacTierra::Settings&)inSettings
{
    if ((self = [super init]))
    {
        mSettings = new MacTierra::Settings(inSettings);
        
        NSString* defaultsFilePath = [[NSBundle mainBundle] pathForResource:@"MutationRateDefaults" ofType:@"plist"];
        self.mutationDefaults = [NSDictionary dictionaryWithContentsOfFile:defaultsFilePath];
        
        [self setInitialLevels];
    }
    return self;
}

- (void)dealloc
{
    self.mutationDefaults = nil;
    delete mSettings;
    [super dealloc];
}

- (void)setSoupSize:(NSUInteger)inSize
{
    [self willChangeValueForKey:@"soupSize"];
    soupSize = inSize;
    mSettings->updateWithSoupSize(soupSize);
    [self didChangeValueForKey:@"soupSize"];
}

- (const MacTierra::Settings*)settings
{
    return mSettings;
}

- (MacTierra::Settings::ETimeSliceType)timeSliceType
{
    return mSettings->timeSliceType();
}

- (void)setTimeSliceType:(MacTierra::Settings::ETimeSliceType)inVal
{
    return mSettings->setTimeSliceType(inVal);
}

- (NSUInteger)constantSliceSize
{
    return mSettings->constantSliceSize();
}

- (void)setConstantSliceSize:(NSUInteger)inVal
{
    mSettings->setConstantSliceSize(inVal);
}

- (double)sliceSizeVariance
{
    return mSettings->sliceSizeVariance();
}

- (void)setSliceSizeVariance:(double)inVal
{
    mSettings->setSliceSizeVariance(inVal);
}

- (double)sizeSelection
{
    return mSettings->sizeSelection();
}

- (void)setSizeSelection:(double)inVal
{
    mSettings->setSizeSelection(inVal);
}

- (double)reapThreshold
{
    return mSettings->reapThreshold();
}

- (void)setReapThreshold:(double)inVal
{
    mSettings->setReapThreshold(inVal);
}

- (double)flawRate
{
    return mSettings->flawRate();
}

- (void)setFlawRate:(double)inVal
{
    mSettings->setFlawRate(inVal);
    [self updateFlawLevel];
}

- (double)meanFlawInterval
{
    return mSettings->meanFlawInterval();
}

- (void)setMeanFlawInterval:(double)inVal
{
    [self willChangeValueForKey:@"flawRate"];
    mSettings->setFlawRate(1.0 / inVal);
    [self didChangeValueForKey:@"flawRate"];
    [self updateFlawLevel];
}

- (double)cosmicRate
{
    return mSettings->cosmicRate();
}

- (void)setCosmicRate:(double)inVal
{
    [self willChangeValueForKey:@"meanCosmicTimeInterval"];
    mSettings->setCosmicRate(inVal, soupSize);
    [self didChangeValueForKey:@"meanCosmicTimeInterval"];
    [self updateCosmicMutationLevel];
}

- (double)meanCosmicTimeInterval
{
    return mSettings->meanCosmicTimeInterval();
}

- (void)setMeanCosmicTimeInterval:(double)inVal
{
    [self willChangeValueForKey:@"cosmicRate"];
    double cosmicRate = 1.0 / (inVal * soupSize);
    mSettings->setCosmicRate(cosmicRate, soupSize);
    [self didChangeValueForKey:@"cosmicRate"];
    [self updateCosmicMutationLevel];
}

- (double)copyErrorRate
{
    return mSettings->copyErrorRate();
}

- (void)setCopyErrorRate:(double)inVal
{
    mSettings->setCopyErrorRate(inVal);
    [self updateCopyErrorLevel];
}

- (double)meanCopyErrorInterval
{
    return mSettings->meanCopyErrorInterval();
}

- (void)setMeanCopyErrorInterval:(double)inVal
{
    [self willChangeValueForKey:@"copyErrorRate"];
    mSettings->setCopyErrorRate(1.0 / inVal);
    [self didChangeValueForKey:@"copyErrorRate"];
    [self updateCopyErrorLevel];
}

- (MacTierra::Settings::EMutationType)mutationType
{
    return mSettings->mutationType();
}

- (void)setMutationType:(MacTierra::Settings::EMutationType)inVal
{
    return mSettings->setMutationType(inVal);
}

- (MacTierra::Settings::EDaughterAllocationStrategy)daughterAllocationStrategy
{
    return mSettings->daughterAllocationStrategy();
}

- (void)setDaughterAllocationStrategy:(MacTierra::Settings::EDaughterAllocationStrategy)inVal
{
    return mSettings->setDaughterAllocationStrategy(inVal);
}

- (BOOL)globalWritesAllowed
{
    return mSettings->globalWritesAllowed();
}

- (void)setGlobalWritesAllowed:(BOOL)inVal
{
    mSettings->setGlobalWritesAllowed(inVal);
}

- (BOOL)transferRegistersToOffspring
{
    return mSettings->transferRegistersToOffspring();
}

- (void)setTransferRegistersToOffspring:(BOOL)inVal
{
    mSettings->setTransferRegistersToOffspring(inVal);
}

- (BOOL)clearDaughterCells
{
    return mSettings->clearDaughterCells();
}

- (void)setClearDaughterCells:(BOOL)inVal
{
    mSettings->setClearDaughterCells(inVal);
}

- (BOOL)clearReapedCreatures
{
    return mSettings->clearReapedCreatures();
}

- (void)setClearReapedCreatures:(BOOL)inVal
{
    mSettings->setClearReapedCreatures(inVal);
}

#pragma mark -

- (void)setCosmicMutationLevel:(EMutationRate)inLevel
{
    double rateVal = [self defaultRateForType:@"cosmic-rays" level:inLevel];
    cosmicMutationLevel = inLevel;
    self.cosmicRate = rateVal;
}

- (void)setFlawLevel:(EMutationRate)inLevel
{
    double rateVal = [self defaultRateForType:@"instruction-flaws" level:inLevel];
    flawLevel = inLevel;
    self.flawRate = rateVal;
}

- (void)setCopyErrorLevel:(EMutationRate)inLevel
{
    double rateVal = [self defaultRateForType:@"copy-errors" level:inLevel];
    copyErrorLevel = inLevel;
    self.copyErrorRate = rateVal;
}

#pragma mark -

- (void)updateCosmicMutationLevel
{
    NSDictionary* mutationLevelDict = [mutationDefaults objectForKey:@"cosmic-rays"];
    int curLevel = 0;
    if (mSettings->cosmicRate() > 0.0)
    {
        for (curLevel = (int)kNone; curLevel <= (int)kVeryHigh; ++curLevel)
        {
            double levelVal = [[mutationLevelDict objectForKey:[self keyForLevel:(EMutationRate)curLevel]] doubleValue];
            double delta = fabs(levelVal - mSettings->cosmicRate()) / mSettings->cosmicRate();
            if (delta < 0.001)
                break;
        }
    }
    
    [self willChangeValueForKey:@"cosmicMutationLevel"];
    // avoid the setter which will recurse
    cosmicMutationLevel = (EMutationRate)curLevel;
    [self didChangeValueForKey:@"cosmicMutationLevel"];
}

- (void)updateFlawLevel
{
    NSDictionary* mutationLevelDict = [mutationDefaults objectForKey:@"instruction-flaws"];
    int curLevel = 0;
    if (mSettings->flawRate() > 0.0)
    {
        for (curLevel = (int)kNone; curLevel <= (int)kVeryHigh; ++curLevel)
        {
            double levelVal = [[mutationLevelDict objectForKey:[self keyForLevel:(EMutationRate)curLevel]] doubleValue];
            double delta = fabs(levelVal - mSettings->flawRate()) / mSettings->flawRate();
            if (delta < 0.001)
                break;
        }
    }
    
    [self willChangeValueForKey:@"flawLevel"];
    // avoid the setter which will recurse
    flawLevel = (EMutationRate)curLevel;
    [self didChangeValueForKey:@"flawLevel"];
}

- (void)updateCopyErrorLevel
{
    NSDictionary* mutationLevelDict = [mutationDefaults objectForKey:@"copy-errors"];
    int curLevel = 0;
    if (mSettings->copyErrorRate() > 0.0)
    {
        for (curLevel = (int)kNone; curLevel <= (int)kVeryHigh; ++curLevel)
        {
            double levelVal = [[mutationLevelDict objectForKey:[self keyForLevel:(EMutationRate)curLevel]] doubleValue];
            double delta = fabs(levelVal - mSettings->copyErrorRate()) / mSettings->copyErrorRate();
            if (delta < 0.001)
                break;
        }
    }

    [self willChangeValueForKey:@"copyErrorLevel"];
    // avoid the setter which will recurse
    copyErrorLevel = (EMutationRate)curLevel;
    [self didChangeValueForKey:@"copyErrorLevel"];
}

- (void)setInitialLevels
{
    [self updateCosmicMutationLevel];
    [self updateFlawLevel];
    [self updateCopyErrorLevel];
        
}

- (NSString*)keyForLevel:(EMutationRate)inLevel
{
    switch (inLevel)
    {
        case kNone:     return @"none";
        case kLow:      return @"low";
        case kMedium:   return @"medium";
        case kHigh:     return @"high";
        case kVeryHigh: return @"very-high";
        case kOther:    return @"";
    }
    return @"";
}

- (double)defaultRateForType:(NSString*)inType level:(EMutationRate)inLevel
{
    double result = 0.0;

    NSDictionary* typeDict = [mutationDefaults objectForKey:inType];
    if (typeDict)
    {
        NSNumber* value = [typeDict objectForKey:[self keyForLevel:inLevel]];
        if (value)
            result = [value doubleValue];
    }
    
    return result;
}

@end
