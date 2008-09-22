//
//  MTGenebankWindowController.h
//  MacTierra
//
//  Created by Simon Fraser on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTGenebankController;

@interface MTGenebankWindowController : NSWindowController
{
    IBOutlet NSArrayController*      mGenebankArrayController;
}

@property (readonly) MTGenebankController* genebankController;

@end
