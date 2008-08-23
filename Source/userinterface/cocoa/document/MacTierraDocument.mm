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

@implementation MacTierraDocument

@synthesize worldController;
@synthesize startEmpty;

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
    [worldController release]; // ??
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"MacTierraDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [worldController createSoup:(256 * 1024)];
    if (!startEmpty)
        [worldController seedWithAncestor];

    [super windowControllerDidLoadNib:aController];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

- (void)close
{
    [worldController documentClosing];
    [super close];
}

@end
