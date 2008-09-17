//
//  MTGenebankController.mm
//  MacTierra
//
//  Created by Simon Fraser on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSArrayAdditions.h"

#import "MTGenebankController.h"

static MTGenebankController* gGenebankController = nil;

@interface MTGenebankController(Private)

- (void)setupContext;
- (NSString*)directoryForGenebankFile;

@end

#pragma mark -

@implementation MTGenebankController

+ (MTGenebankController*)sharedGenebankController
{
    if (!gGenebankController)
        gGenebankController = [[MTGenebankController alloc] init];

    return gGenebankController;
}


- (id)init
{
    if ((self = [super init]))
    {
        [self setupContext];
        
        // testing
        unsigned char bytes[] = { 0x01, 0x00, 0x19, 0x1F };
        [self enterGenome:[NSData dataWithBytes:bytes length:sizeof(bytes)]];
    }
    return self;
}

- (void)dealloc
{
    [mObjectContext release];
    [mStoreCoordinator release];
    [mObjectModel release];
    
    
    [super dealloc];
}

- (NSManagedObjectContext*)managedObjectContext
{
    return mObjectContext;
}

- (void)synchronize
{
    NSError* saveError = nil;
    if ([mObjectContext hasChanges] && ![mObjectContext save:&saveError])
    {
        NSLog(@"Saving genebank failed with error %@", saveError);
    }
}

- (id)entryWithGenome:(NSData*)genome
{
    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"Genotype" inManagedObjectContext:mObjectContext];

    NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"genome == %@", genome];
    [request setPredicate:predicate];

    NSError* queryError = nil;
    NSArray* results = [mObjectContext executeFetchRequest:request error:&queryError];
    if (!results && queryError)
        NSLog(@"Search for genome in genebank returned error %@", queryError);

    return [results firstObject];
}

- (void)enterGenome:(NSData*)inData
{
    id newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"Genotype" inManagedObjectContext:mObjectContext];

    [newEntry setValue:@"Bob" forKey:@"name"];
    [newEntry setValue:[NSNumber numberWithUnsignedInteger:[inData length]] forKey:@"length"];
    [newEntry setValue:inData forKey:@"genome"];
    
}

- (void)setupContext
{
    NSString* schemaFilePath = [[NSBundle mainBundle] pathForResource:@"Genebank" ofType:@"mom"];
    NSURL*  schemaFileURL = [NSURL fileURLWithPath:schemaFilePath];
    
    mObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:schemaFileURL];

    mStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mObjectModel];
    
    NSString* genebankDir = [self directoryForGenebankFile];

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* createDirsError = nil;
    if (![fileManager createDirectoryAtPath:genebankDir withIntermediateDirectories:YES attributes:nil error:&createDirsError])
        NSLog(@"Error %@ creating directory %@", createDirsError, genebankDir);

    NSString* genebankFilePath = [genebankDir stringByAppendingPathComponent:@"Genebank.sql"];
    NSURL* databaseURL = [NSURL fileURLWithPath:genebankFilePath];
    
    NSError* error = nil;
    [mStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:databaseURL options:0 error:&error];
    if (error)
        NSLog(@"Error %@ opening persistent store at %@", error, databaseURL);

    mObjectContext = [[NSManagedObjectContext alloc] init];
    [mObjectContext setPersistentStoreCoordinator:mStoreCoordinator];
}

- (NSString*)directoryForGenebankFile
{
    NSString* appName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    if (![appName length])
        appName = @"MacTierra";

    NSString* appSupport = nil;
    NSArray*  dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ([dirs count] > 0)
        appSupport = [dirs objectAtIndex:0];
    else
        appSupport = [@"~/Library/Application Support/" stringByExpandingTildeInPath];
    
    return [appSupport stringByAppendingPathComponent:appName];
}








@end
