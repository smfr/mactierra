//
//  MacTierraDocument.h
//  MacTierra
//
//  Created by Simon Fraser on 8/10/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class MTWorldController;

extern NSString* const kEmptySoupDocumentType;

@interface MacTierraDocument : NSDocument
{
    IBOutlet MTWorldController* worldController;

    BOOL                        startEmpty;
}

@property (retain) MTWorldController*   worldController;
@property (assign) BOOL startEmpty;

@end
