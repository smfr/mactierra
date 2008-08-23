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
    BOOL        creatingEmptySoup;
}

@property (assign) BOOL creatingEmptySoup;

- (IBAction)newEmptySoupDocument:(id)sender;

@end
