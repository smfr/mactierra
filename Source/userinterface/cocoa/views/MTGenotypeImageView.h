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
}

@property (nonatomic, retain) MTInventoryGenotype* genotype;
@property (nonatomic, weak) IBOutlet MTWorldController* worldController;

@end
