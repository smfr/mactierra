//
//  MTGraphController.h
//  MacTierra
//
//  Created by Simon Fraser on 8/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTWorldController;


typedef enum ESoupStatistic {
    kPopulationSize = 1,
    kMeanCreatureSize,
    kNumGenotypes,
    kMeanOffspring,
    kCommonestGenotypeFitness,

    kCreatureSizeFrequencies
    
} ESoupStatistic;



@interface MTGraphController : NSObject
{
    IBOutlet MTWorldController*  mWorldController;
    IBOutlet NSView*    mGraphContainerView;

    IBOutlet NSView*    mGraphAdditionsView;
    
    NSMutableArray*     graphs;

    NSInteger           currentGraphIndex;
}

// Available graph values: "localizedName"
@property (retain) NSMutableArray* graphs;
@property (assign) NSInteger currentGraphIndex;

- (void)worldChanged;
- (void)updateGraph;

@end
