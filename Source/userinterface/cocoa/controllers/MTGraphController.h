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
}

@property (nonatomic, weak) IBOutlet MTWorldController*  worldController;

// Available graph values: "localizedName"
@property (nonatomic, retain) NSMutableArray* graphs;

- (void)worldChanged;
- (void)updateGraph;

- (void)documentClosing;

@end

@class MTGenotypeImageView;

@interface TwoGenotypesViewController : NSViewController
{
    IBOutlet NSObjectController*    firstGenotypeController;
    IBOutlet NSObjectController*    secondGenotypeController;
    
    IBOutlet MTGenotypeImageView*   firstGenotypeImageView;
    IBOutlet MTGenotypeImageView*   secondGenotypeImageView;
}

- (MTGenotypeImageView*)firstGenotypeImageView;
- (MTGenotypeImageView*)secondGenotypeImageView;

- (void)setupBindings;
- (void)clearBindings;

@end
