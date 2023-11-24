//
//  MTDocumentController.h
//  MacTierra
//
//  Created by Simon Fraser on 8/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MTDocumentController : NSDocumentController
{
}

@property (nonatomic, assign) BOOL creatingEmptySoup;

- (IBAction)newEmptySoupDocument:(id)sender;

@end
