//
//  MacTierraDocument.h
//  MacTierra
//
//  Created by Simon Fraser on 8/10/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class MTWorldController;

@interface MacTierraDocument : NSDocument
{
    IBOutlet MTWorldController*      worldController;
}

@property (retain) MTWorldController*   worldController;

@end
