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
    class Soup;
};


@interface MTSoupView : MTCompositedGLView
{
    MacTierra::Soup*    mSoup;
    
    int                 mSoupWidth;
    int                 mSoupHeight;
    
    BOOL                mZoomToFit;
}

- (void)setSoup:(MacTierra::Soup*)inSoup;
- (MacTierra::Soup*)soup;

@end
