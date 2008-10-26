//
//  MTGenotypeImageView.h
//  MacTierra
//
//  Created by Simon Fraser on 10/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTWorldController;
@class MTCreature;

@interface MTGenotypeImageView : NSImageView
{
    IBOutlet MTWorldController* worldController;
    
    MTCreature* creature;
}

@property (retain) MTCreature* creature;

@end
