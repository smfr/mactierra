//
//  MacTierraDocument.m
//  MacTierra
//
//  Created by Simon Fraser on 8/10/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "MacTierraDocument.h"

#import "MTDocumentController.h"
#import "MTWorldController.h"

NSString* const kBinarySoupDocumentType = @"SoupDocumentType";  // has to match the plist
NSString* const kXMLSoupDocumentType = @"XMLSoupDocumentType";  // has to match the plist

NSString* const kMacTierraErrorDomain = @"org.smfr.mactierra.error-domain";

@implementation MacTierraDocument

@synthesize worldController;
@synthesize startEmpty;
@synthesize soupData;
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
    self.soupData = nil;
    [worldController release]; // ??
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"MacTierraDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    if (soupData)
    {
        if (dataIsXML)
            [worldController setWorldWithXMLData:soupData];
        else
            [worldController setWorldWithData:soupData];

        self.soupData = nil;
    }
    else
    {
        [worldController createSoup:(256 * 1024)];
        if (!startEmpty)
            [worldController seedWithAncestor];
    }
    
    [super windowControllerDidLoadNib:aController];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSData* worldData = nil;
    if ([typeName isEqualToString:kBinarySoupDocumentType])
        worldData = [worldController worldData];
    else if ([typeName isEqualToString:kXMLSoupDocumentType])
        worldData = [worldController worldXMLData];

    if (!worldData && outError != NULL)
        *outError = [NSError errorWithDomain:kMacTierraErrorDomain code:-1 userInfo:NULL];

    return worldData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // have to wait until the window controller is hooked up in windowControllerDidLoadNib:
    if ([typeName isEqualToString:kBinarySoupDocumentType] || [typeName isEqualToString:kXMLSoupDocumentType])
    {
        self.soupData = data;
        self.dataIsXML = [typeName isEqualToString:kXMLSoupDocumentType];
        return YES;
    }
    return NO;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL reverting = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
    if (reverting)
    {
        if ([typeName isEqualToString:kBinarySoupDocumentType])
            [worldController setWorldWithData:self.soupData];
        else if ([typeName isEqualToString:kXMLSoupDocumentType])
            [worldController setWorldWithXMLData:self.soupData];

        self.soupData = nil;
    }
    
    return reverting;
}

- (void)close
{
    [worldController documentClosing];
    [super close];
}

- (IBAction)showSettings:(id)sender
{
    [worldController showSettings:sender];
}

- (IBAction)toggleRunning:(id)sender
{
    [worldController toggleRunning:sender];
}

- (IBAction)step:(id)sender
{
    [worldController step:sender];
}

@end
