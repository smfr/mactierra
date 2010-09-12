//
//  MacTierraDocument.m
//  MacTierra
//
//  Created by Simon Fraser on 8/10/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "MacTierraDocument.h"

#include <iostream>
#include <fstream>

#import "MTSoupView.h"
#import "MTDocumentController.h"
#import "MTWorldController.h"

NSString* const kBinarySoupDocumentType     = @"SoupDocumentType";  // has to match the plist
NSString* const kXMLSoupDocumentType        = @"XMLSoupDocumentType";  // has to match the plist

NSString* const kMacTierraErrorDomain   = @"org.smfr.mactierra.error-domain";

@implementation MacTierraDocument

@synthesize worldController;
@synthesize startEmpty;
@synthesize pendingFileURL;
@synthesize dataIsXML;

- (id)init
{
    if (self = [super init])
    {

    }
    return self;
}

// new, empty document
- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
    if (self = [super init])
    {
        if ([(MTDocumentController*)[NSDocumentController sharedDocumentController] creatingEmptySoup])
            self.startEmpty = YES;
    }
    return self;
}

- (void)dealloc
{
    self.fileURL = nil;
    [worldController release]; // ??
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"MacTierraDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    if (pendingFileURL)
    {
        if (dataIsXML)
            [worldController readWorldFromXMLFile:pendingFileURL];
        else
            [worldController readWorldFromBinaryFile:pendingFileURL];

        self.pendingFileURL = nil;
    }
    else
    {
        if (self.startEmpty)
            [worldController newEmptySoup:nil];
        else
            [worldController performSelector:@selector(newSoupShowingSettings:) withObject:nil afterDelay:0];
    }
    
    [super windowControllerDidLoadNib:aController];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL succeeded = NO;
    
    if ([typeName isEqualToString:kBinarySoupDocumentType])
        succeeded = [worldController writeWorldToBinaryFile:absoluteURL];
    else if ([typeName isEqualToString:kXMLSoupDocumentType])
        succeeded = [worldController writeWorldToXMLFile:absoluteURL];

    if (!succeeded && outError != NULL)
        *outError = [NSError errorWithDomain:kMacTierraErrorDomain code:-1 userInfo:NULL];

    return succeeded;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;
{
    // have to wait until the window controller is hooked up in windowControllerDidLoadNib:
    if ([typeName isEqualToString:kBinarySoupDocumentType] || [typeName isEqualToString:kXMLSoupDocumentType])
    {
        self.pendingFileURL = absoluteURL;
        self.dataIsXML = [typeName isEqualToString:kXMLSoupDocumentType];
        return YES;
    }
    return NO;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL reverting = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
    BOOL succeeded = NO;
    if (reverting)
    {
        [worldController clearWorld];

        if ([typeName isEqualToString:kBinarySoupDocumentType])
            succeeded = [worldController readWorldFromBinaryFile:self.pendingFileURL];
        else if ([typeName isEqualToString:kXMLSoupDocumentType])
            succeeded = [worldController readWorldFromXMLFile:self.pendingFileURL];

        self.pendingFileURL = nil;
    }
    
    return succeeded;
}

- (void)close
{
    [worldController documentClosing];
    worldController = 0;
    [super close];
}

- (IBAction)showSettings:(id)sender
{
    [worldController editSoupSettings:sender];
}

- (IBAction)exportSettings:(id)sender
{
    NSSavePanel*    savePanel = [NSSavePanel savePanel];
    
    [savePanel beginSheetForDirectory:nil
                                 file:NSLocalizedString(@"ConfigurationFilename", @"")
                       modalForWindow:[self windowForSheet]
                        modalDelegate:self
                       didEndSelector:@selector(exportSettingsPanelDidDne:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (void)exportSettingsPanelDidDne:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton)
    {
        [worldController writeSoupConfigurationToXMLFile:[sheet URL]];
    }
}

- (IBAction)toggleRunning:(id)sender
{
    [worldController toggleRunning:sender];
}

- (IBAction)step:(id)sender
{
    [worldController step:sender];
}

- (IBAction)toggleCellsVisibility:(id)sender
{
    mSoupView.showCells = !mSoupView.showCells;
}

- (IBAction)toggleInstructionPointersVisibility:(id)sender
{
    mSoupView.showInstructionPointers = !mSoupView.showInstructionPointers;
}

- (IBAction)toggleFecundityVisibility:(id)sender
{
    mSoupView.showFecundity = !mSoupView.showFecundity;
}

#pragma mark -

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
    if ([anItem action] == @selector(toggleCellsVisibility:))
    {
        if ([(NSObject*)anItem isKindOfClass:[NSMenuItem self]])
            [(NSMenuItem*)anItem setTitle:mSoupView.showCells ? NSLocalizedString(@"HideCells", @"") : NSLocalizedString(@"ShowCells", @"")];
        
        return YES;
    }

    if ([anItem action] == @selector(toggleInstructionPointersVisibility:))
    {
        if ([(NSObject*)anItem isKindOfClass:[NSMenuItem self]])
            [(NSMenuItem*)anItem setTitle:mSoupView.showInstructionPointers ? NSLocalizedString(@"HideInstructionPointers", @"") : NSLocalizedString(@"ShowInstructionPointers", @"")];
        
        return YES;
    }

    if ([anItem action] == @selector(toggleFecundityVisibility:))
    {
        if ([(NSObject*)anItem isKindOfClass:[NSMenuItem self]])
            [(NSMenuItem*)anItem setTitle:mSoupView.showFecundity ? NSLocalizedString(@"HideFecundity", @"") : NSLocalizedString(@"ShowFecundity", @"")];
        
        return YES;
    }

    return YES;
}

@end
