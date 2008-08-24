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

NSString* const kEmptySoupDocumentType = @"EmptySoupDocumentType";  // has to match the plist

NSString* const kMacTierraErrorDomain = @"org.smfr.mactierra.error-domain";

@implementation MacTierraDocument

@synthesize worldController;
@synthesize startEmpty;
@synthesize soupData;

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
    NSData* worldData = [worldController worldData];

    if (!worldData && outError != NULL)
        *outError = [NSError errorWithDomain:kMacTierraErrorDomain code:-1 userInfo:NULL];

    return worldData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // have to wait until the window controller is hooked up in windowControllerDidLoadNib:
    self.soupData = data;
    return YES;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL reverting = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
    if (reverting)
    {
        [worldController setWorldWithData:soupData];
        self.soupData = nil;
    }
    
    return reverting;
}

- (void)close
{
    [worldController documentClosing];
    [super close];
}

@end
