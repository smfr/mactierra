//
//  MTApplicationController.h
//  MacTierra
//
//  Created by Simon Fraser on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTGenebankController;
@class MTGenebankWindowController;

@interface MTApplicationController : NSObject
{
}

@property (nonatomic, retain, readonly) MTGenebankController* genebankController;

- (IBAction)showGenebankWindow:(id)sender;

@end
