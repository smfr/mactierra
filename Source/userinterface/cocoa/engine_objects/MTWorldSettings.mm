//
//  MTWorldSettings.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTWorldSettings.h"


@implementation MTWorldSettings

@synthesize soupSize;

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObject:@"flawRate"]
                                triggerChangeNotificationsForDependentKey:@"meanFlawInterval"];
}


- (id)initWithSettings:(const MacTierra::Settings&)inSettings
{
    if ((self = [super init]))
    {
        mSettings = new MacTierra::Settings(inSettings);
    }
    return self;
}

- (void)dealloc
{
    delete mSettings;
    [super dealloc];
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
}

- (double)meanFlawInterval
{
    return mSettings->meanFlawInterval();
}

- (double)cosmicRate
{
    return mSettings->cosmicRate();
}

- (void)setCosmicRate:(double)inVal
{
    mSettings->setCosmicRate(inVal, soupSize);
}

- (double)meanCosmicTimeInterval
{
    return mSettings->meanCosmicTimeInterval();
}

- (double)copyErrorRate
{
    return mSettings->copyErrorRate();
}

- (void)setCopyErrorRate:(double)inVal
{
    mSettings->setCopyErrorRate(inVal);
}

- (double)meanCopyErrorInterval
{
    return mSettings->meanCopyErrorInterval();
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

- (BOOL)clearReapedCreatures
{
    return mSettings->clearReapedCreatures();
}

- (void)setClearReapedCreatures:(BOOL)inVal
{
    mSettings->setClearReapedCreatures(inVal);
}



@end
