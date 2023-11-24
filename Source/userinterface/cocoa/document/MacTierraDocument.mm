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


@interface MacTierraDocument ( )

@property (nonatomic, weak) IBOutlet MTSoupView* soupView;

@end

#pragma mark -

@implementation MacTierraDocument

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

- (NSString *)windowNibName
{
    return @"MacTierraDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    if (_pendingFileURL)
    {
        if (_dataIsXML)
            [_worldController readWorldFromXMLFile:_pendingFileURL];
        else
            [_worldController readWorldFromBinaryFile:_pendingFileURL];

        self.pendingFileURL = nil;
    }
    else
    {
        if (self.startEmpty)
            [_worldController newEmptySoup:nil];
        else
            [_worldController performSelector:@selector(newSoupShowingSettings:) withObject:nil afterDelay:0];
    }
    
    [super windowControllerDidLoadNib:aController];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL succeeded = NO;
    
    if ([typeName isEqualToString:kBinarySoupDocumentType])
        succeeded = [_worldController writeWorldToBinaryFile:absoluteURL];
    else if ([typeName isEqualToString:kXMLSoupDocumentType])
        succeeded = [_worldController writeWorldToXMLFile:absoluteURL];

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
        [_worldController clearWorld];

        if ([typeName isEqualToString:kBinarySoupDocumentType])
            succeeded = [_worldController readWorldFromBinaryFile:self.pendingFileURL];
        else if ([typeName isEqualToString:kXMLSoupDocumentType])
            succeeded = [_worldController readWorldFromXMLFile:self.pendingFileURL];

        self.pendingFileURL = nil;
    }
    
    return succeeded;
}

- (void)close
{
    [_worldController documentClosing];
    _worldController = nil;
    [super close];
}

- (IBAction)showSettings:(id)sender
{
    [_worldController editSoupSettings:sender];
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
    if (returnCode == NSModalResponseOK)
    {
        [_worldController writeSoupConfigurationToXMLFile:[sheet URL]];
    }
}

- (IBAction)toggleRunning:(id)sender
{
    [_worldController toggleRunning:sender];
}

- (IBAction)step:(id)sender
{
    [_worldController step:sender];
}

- (IBAction)toggleCellsVisibility:(id)sender
{
    _soupView.showCells = !_soupView.showCells;
}

- (IBAction)toggleInstructionPointersVisibility:(id)sender
{
    _soupView.showInstructionPointers = !_soupView.showInstructionPointers;
}

- (IBAction)toggleFecundityVisibility:(id)sender
{
    _soupView.showFecundity = !_soupView.showFecundity;
}

#pragma mark -

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
    if ([anItem action] == @selector(toggleCellsVisibility:))
    {
        if ([(NSObject*)anItem isKindOfClass:[NSMenuItem self]])
            [(NSMenuItem*)anItem setTitle:_soupView.showCells ? NSLocalizedString(@"HideCells", @"") : NSLocalizedString(@"ShowCells", @"")];
        
        return YES;
    }

    if ([anItem action] == @selector(toggleInstructionPointersVisibility:))
    {
        if ([(NSObject*)anItem isKindOfClass:[NSMenuItem self]])
            [(NSMenuItem*)anItem setTitle:_soupView.showInstructionPointers ? NSLocalizedString(@"HideInstructionPointers", @"") : NSLocalizedString(@"ShowInstructionPointers", @"")];
        
        return YES;
    }

    if ([anItem action] == @selector(toggleFecundityVisibility:))
    {
        if ([(NSObject*)anItem isKindOfClass:[NSMenuItem self]])
            [(NSMenuItem*)anItem setTitle:_soupView.showFecundity ? NSLocalizedString(@"HideFecundity", @"") : NSLocalizedString(@"ShowFecundity", @"")];
        
        return YES;
    }

    return YES;
}

@end
