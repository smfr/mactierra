//
//  MTWorldSettings.h
//  MacTierra
//
//  Created by Simon Fraser on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MT_Settings.h"

typedef enum ESoupSizePreset {
    k64K,
    k128K,
    k256K,
    k512K,
    k1M,
    k2M,
    k4M,
    kOtherSize
} ESoupSizePreset;


typedef enum EMutationRate {
    kNone,
    kLow,
    kMedium,
    kHigh,
    kVeryHigh,
    kOtherRate
} EMutationRate;

@interface MTWorldSettings : NSObject
{
    MacTierra::Settings*    mSettings;
}

- (id)initWithSettings:(const MacTierra::Settings&)inSettings;
@property (nonatomic, readonly) const MacTierra::Settings* settings;

@property (nonatomic, assign) NSUInteger soupSize;
@property (nonatomic, assign) ESoupSizePreset soupSizePreset;
@property (nonatomic, assign) BOOL creatingNewSoup;
@property (nonatomic, assign) BOOL seedWithAncestor;

@property (nonatomic, assign) NSUInteger randomSeed;

@property (nonatomic, assign) MacTierra::Settings::ETimeSliceType timeSliceType;

@property (nonatomic, assign) NSUInteger constantSliceSize;

@property (nonatomic, assign) double sliceSizeVariance;
@property (nonatomic, assign) double sizeSelection;
@property (nonatomic, assign) double reapThreshold;

@property (nonatomic, assign) EMutationRate flawLevel;
@property (nonatomic, assign) double flawRate;
@property (nonatomic, assign) double meanFlawInterval;

@property (nonatomic, assign) EMutationRate cosmicMutationLevel;
@property (nonatomic, assign) double cosmicRate;
@property (nonatomic, assign) double meanCosmicTimeInterval;

@property (nonatomic, assign) EMutationRate copyErrorLevel;
@property (nonatomic, assign) double copyErrorRate;
@property (nonatomic, assign) double meanCopyErrorInterval;

@property (nonatomic, assign) MacTierra::Settings::EMutationType mutationType;
@property (nonatomic, assign) MacTierra::Settings::EDaughterAllocationStrategy daughterAllocationStrategy;

@property (nonatomic, assign) BOOL globalWritesAllowed;
@property (nonatomic, assign) BOOL transferRegistersToOffspring;
@property (nonatomic, assign) BOOL clearDaughterCells;
@property (nonatomic, assign) BOOL clearReapedCreatures;
@property (nonatomic, assign) BOOL selectForLeanness;

@end
