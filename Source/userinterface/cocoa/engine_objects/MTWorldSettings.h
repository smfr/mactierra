//
//  MTWorldSettings.h
//  MacTierra
//
//  Created by Simon Fraser on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MT_Settings.h"

typedef enum EMutationRate {
    kNone,
    kLow,
    kMedium,
    kHigh,
    kVeryHigh,
    kOther
} EMutationRate;

@interface MTWorldSettings : NSObject
{
    MacTierra::Settings*    mSettings;
    
    NSUInteger              soupSize;
    
    EMutationRate           flawLevel;
    EMutationRate           cosmicMutationLevel;
    EMutationRate           copyErrorLevel;
    
    NSDictionary*           mutationDefaults;
}

- (id)initWithSettings:(const MacTierra::Settings&)inSettings;
@property (readonly) const MacTierra::Settings* settings;

@property (assign) NSUInteger soupSize;

@property (assign) MacTierra::Settings::ETimeSliceType timeSliceType;

@property (assign) NSUInteger constantSliceSize;

@property (assign) double sliceSizeVariance;
@property (assign) double sizeSelection;
@property (assign) double reapThreshold;

@property (assign) EMutationRate flawLevel;
@property (assign) double flawRate;
@property (assign) double meanFlawInterval;

@property (assign) EMutationRate cosmicMutationLevel;
@property (assign) double cosmicRate;
@property (assign) double meanCosmicTimeInterval;

@property (assign) EMutationRate copyErrorLevel;
@property (assign) double copyErrorRate;
@property (assign) double meanCopyErrorInterval;

@property (assign) MacTierra::Settings::EMutationType mutationType;
@property (assign) MacTierra::Settings::EDaughterAllocationStrategy daughterAllocationStrategy;

@property (assign) BOOL globalWritesAllowed;
@property (assign) BOOL transferRegistersToOffspring;
@property (assign) BOOL clearDaughterCells;
@property (assign) BOOL clearReapedCreatures;


// internal
@property (retain) NSDictionary* mutationDefaults;

@end
