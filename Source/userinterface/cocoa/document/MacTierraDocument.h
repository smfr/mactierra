//
//  MacTierraDocument.h
//  MacTierra
//
//  Created by Simon Fraser on 8/10/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

extern NSString* const kBinarySoupDocumentType;
extern NSString* const kXMLSoupDocumentType;

@class MTWorldController;

@interface MacTierraDocument : NSDocument
{
}

@property (nonatomic, weak) IBOutlet MTWorldController* worldController;
@property (nonatomic, retain) NSURL* pendingFileURL;
@property (nonatomic, assign) BOOL dataIsXML;
@property (nonatomic, assign) BOOL startEmpty;


- (IBAction)showSettings:(id)sender;
- (IBAction)exportSettings:(id)sender;

- (IBAction)toggleRunning:(id)sender;
- (IBAction)step:(id)sender;

- (IBAction)toggleCellsVisibility:(id)sender;
- (IBAction)toggleInstructionPointersVisibility:(id)sender;
- (IBAction)toggleFecundityVisibility:(id)sender;

@end
