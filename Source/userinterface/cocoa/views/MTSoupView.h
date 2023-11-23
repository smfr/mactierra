//
//  MTSoupView.h
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MTCompositedGLView.h"

namespace MacTierra {
    class World;
};

@class MTWorldController;

@interface MTSoupView : NSView
{
    IBOutlet MTWorldController*     mWorldController;
    IBOutlet NSArrayController*     mGenotypesArrayController;
    
    MacTierra::World*   mWorld;
    
    int                 mSoupWidth;
    int                 mSoupHeight;
    
    BOOL                zoomToFit;
    BOOL                showCells;
    BOOL                showInstructionPointers;
    BOOL                showFecundity;
    
    NSString*           focusedCreatureName;

}

- (void)setWorld:(MacTierra::World*)inWorld;
- (MacTierra::World*)world;

@property (assign, nonatomic) BOOL zoomToFit;
@property (assign, nonatomic) BOOL showCells;
@property (assign, nonatomic) BOOL showInstructionPointers;
@property (assign, nonatomic) BOOL showFecundity;

@property (assign, nonatomic) NSString* focusedCreatureName;


@end
