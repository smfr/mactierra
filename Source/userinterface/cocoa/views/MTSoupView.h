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


@interface MTSoupView : MTCompositedGLView
{
    MacTierra::World*   mWorld;
    
    int                 mSoupWidth;
    int                 mSoupHeight;
    
    BOOL                zoomToFit;
    BOOL                showCells;
    BOOL                showInstructionPointers;
    
    NSString*           focusedCreatureName;
}

- (void)setWorld:(MacTierra::World*)inWorld;
- (MacTierra::World*)world;

@property (assign) BOOL zoomToFit;
@property (assign) BOOL showCells;
@property (assign) BOOL showInstructionPointers;

@property (assign) NSString* focusedCreatureName;

@end
