//
//  MTWorldSettings.h
//  MacTierra
//
//  Created by Simon Fraser on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MT_Settings.h"

@interface MTWorldSettings : NSObject
{
    MacTierra::Settings*    mSettings;
    
    double                  soupSize;
}

- (id)initWithSettings:(const MacTierra::Settings&)inSettings;
@property (readonly) const MacTierra::Settings* settings;

@property (assign) double soupSize;

@property (assign) MacTierra::Settings::ETimeSliceType timeSliceType;

@property (assign) NSUInteger constantSliceSize;

@property (assign) double sliceSizeVariance;
@property (assign) double sizeSelection;
@property (assign) double reapThreshold;

@property (assign) double flawRate;
@property (readonly) double meanFlawInterval;

@property (assign) double cosmicRate;
@property (readonly) double meanCosmicTimeInterval;

@property (assign) double copyErrorRate;
@property (readonly) double meanCopyErrorInterval;

@property (assign) MacTierra::Settings::EMutationType mutationType;
@property (assign) MacTierra::Settings::EDaughterAllocationStrategy daughterAllocationStrategy;

@property (assign) BOOL globalWritesAllowed;
@property (assign) BOOL transferRegistersToOffspring;
@property (assign) BOOL clearReapedCreatures;


@end
