//
//  MTGenebankWindowController.m
//  MacTierra
//
//  Created by Simon Fraser on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTGenebankWindowController.h"

#import "MTGenebankController.h"

@implementation MTGenebankWindowController

- (MTGenebankController*)genebankController
{
    return [MTGenebankController sharedGenebankController];
}

@end
