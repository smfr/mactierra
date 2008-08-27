//
//  MacTierraDocument.h
//  MacTierra
//
//  Created by Simon Fraser on 8/10/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class MTWorldController;

extern NSString* const kBinarySoupDocumentType;
extern NSString* const kXMLSoupDocumentType;

@interface MacTierraDocument : NSDocument
{
    IBOutlet MTWorldController* worldController;

    BOOL                        startEmpty;
    
    NSData*                     soupData;
    BOOL                        dataIsXML;
}

@property (retain) MTWorldController*   worldController;
@property (retain) NSData*   soupData;
@property (assign) BOOL dataIsXML;
@property (assign) BOOL startEmpty;


- (IBAction)showSettings:(id)sender;

- (IBAction)toggleRunning:(id)sender;
- (IBAction)step:(id)sender;

@end
