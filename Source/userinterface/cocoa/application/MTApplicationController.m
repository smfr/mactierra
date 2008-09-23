//
//  MTApplicationController.m
//  MacTierra
//
//  Created by Simon Fraser on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTApplicationController.h"

#import "MTValueTransformers.h"

#import "MTGenebankController.h"
#import "MTGenebankWindowController.h"

@implementation MTApplicationController

+ (void)initialize
{
    // register our value transformers
    MTUnsignedIntValueTransformer* unsignedIntVT = [[[MTUnsignedIntValueTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:unsignedIntVT
                                    forName:@"UnsignedIntValueTransformer"];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    mGenebankController = [MTGenebankController sharedGenebankController];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [mGenebankWindowController close];
    [mGenebankWindowController release];
    mGenebankWindowController = nil;

    [mGenebankController shutdown];
    [mGenebankController release];
    mGenebankController = nil;
}

- (MTGenebankController*)genebankController
{
    return mGenebankController;
}

- (IBAction)showGenebankWindow:(id)sender
{
    if (!mGenebankWindowController)
        mGenebankWindowController = [[MTGenebankWindowController alloc] initWithWindowNibName:@"GenebankWindow"];

    [mGenebankWindowController showWindow:sender];
}

@end
