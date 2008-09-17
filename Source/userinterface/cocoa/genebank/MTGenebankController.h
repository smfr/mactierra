//
//  MTGenebankController.h
//  MacTierra
//
//  Created by Simon Fraser on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MTGenebankController : NSObject
{
    NSManagedObjectModel*           mObjectModel;
    NSPersistentStoreCoordinator*   mStoreCoordinator;
    NSManagedObjectContext*         mObjectContext;
}

+ (MTGenebankController*)sharedGenebankController;

@property (readonly) NSManagedObjectContext* managedObjectContext;

- (void)synchronize;

- (id)entryWithGenome:(NSData*)genome;
- (void)enterGenome:(NSData*)inData;

@end
