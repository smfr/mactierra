//
//  MTDocumentController.m
//  MacTierra
//
//  Created by Simon Fraser on 8/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTDocumentController.h"

#import "MacTierraDocument.h"

@implementation MTDocumentController

@synthesize creatingEmptySoup;

- (IBAction)newEmptySoupDocument:(id)sender
{
    self.creatingEmptySoup = YES;
    @try
    {
        [super newDocument:sender];
    }
    @catch(NSException* ex)
    {
        NSLog(@"Got exception %@ when creating new soup document", ex);
    }
    self.creatingEmptySoup = NO;
}

@end
