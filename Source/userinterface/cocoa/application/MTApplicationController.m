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

@interface MTApplicationController ( )

@property (nonatomic, retain) MTGenebankWindowController* genebankWindowController;


@end

@implementation MTApplicationController

+ (void)initialize
{
    // register our value transformers
    MTUnsignedIntValueTransformer* unsignedIntVT = [[MTUnsignedIntValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:unsignedIntVT
                                    forName:@"UnsignedIntValueTransformer"];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _genebankController = [MTGenebankController sharedGenebankController];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [_genebankWindowController close];
    _genebankWindowController = nil;

    [_genebankController shutdown];
    _genebankController = nil;
}

- (IBAction)showGenebankWindow:(id)sender
{
    if (!_genebankWindowController)
        _genebankWindowController = [[MTGenebankWindowController alloc] initWithWindowNibName:@"GenebankWindow"];

    [_genebankWindowController showWindow:sender];
}

@end
