//
//  MTSoupView.h
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

namespace MacTierra {
    class World;
};

@class MTWorldController;

@interface MTSoupView : NSView
{
    int                 mSoupWidth;
    int                 mSoupHeight;
}

@property (assign, nonatomic) MacTierra::World* world;

@property (assign, nonatomic) BOOL zoomToFit;
@property (assign, nonatomic) BOOL showCells;
@property (assign, nonatomic) BOOL showInstructionPointers;
@property (assign, nonatomic) BOOL showFecundity;

@property (assign, nonatomic) NSString* focusedCreatureName;

@end
