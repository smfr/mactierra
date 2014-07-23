//
//  MTGenotypeImageView.h
//  MacTierra
//
//  Created by Simon Fraser on 10/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTWorldController;
@class MTInventoryGenotype;

@interface MTGenotypeImageView : NSImageView
{
    IBOutlet MTWorldController* worldController;
    
    MTInventoryGenotype* genotype;
}

@property (retain, nonatomic) MTInventoryGenotype* genotype;
@property (assign, nonatomic) MTWorldController* worldController;

@end
