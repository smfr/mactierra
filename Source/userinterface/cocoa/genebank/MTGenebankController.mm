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

@interface NSData(Crappy)

- (const char*)UTF8String;

@end

@implementation NSData(Crappy)

- (const char*)UTF8String
{
    NSLog(@"Here");
    return "";
}

@end


@interface MTGenebankController(Private)

- (void)setupContext;
- (NSString*)directoryForGenebankFile;
- (MTGenebankGenotype*)enterGenome:(NSData*)inData name:(NSString*)inName;
- (NSUInteger)numberOfGenotypesOfSize:(NSUInteger)inSize;
- (NSString*)uniqueNameForSize:(NSUInteger)inSize;
- (NSString*)identifierFromCount:(NSUInteger)inCount;

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

- (MTGenebankGenotype*)entryWithGenome:(NSData*)genomeData
{
    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"Genotype" inManagedObjectContext:mObjectContext];

    NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];

    NSExpression* lhs = [NSExpression expressionForKeyPath:@"genome"];
    NSExpression* rhs = [NSExpression expressionForConstantValue:genomeData];

    NSPredicate* equalsPredicate = [NSComparisonPredicate
                                            predicateWithLeftExpression:lhs
                                                        rightExpression:rhs
                                                               modifier:NSDirectPredicateModifier
                                                                   type:NSEqualToPredicateOperatorType
                                                                options:0];
    [request setPredicate:equalsPredicate];

    NSError* queryError = nil;
    NSArray* results = [mObjectContext executeFetchRequest:request error:&queryError];
    if (!results && queryError)
        NSLog(@"Search for genome in genebank returned error %@", queryError);

    return [results firstObject];
}

- (MTGenebankGenotype*)findOrEnterGenome:(NSData*)inData
{
    id foundGenome = [self entryWithGenome:inData];
    if (!foundGenome)
    {
        NSString* name = [self uniqueNameForSize:[inData length]];

        foundGenome = [self enterGenome:inData name:name];
    }
    
    return foundGenome;
}

- (NSUInteger)numberOfGenotypesOfSize:(NSUInteger)inSize
{
    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"Genotype" inManagedObjectContext:mObjectContext];

    NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"length == %u", inSize];
    [request setPredicate:predicate];

    NSError* queryError = nil;
    NSArray* results = [mObjectContext executeFetchRequest:request error:&queryError];
    if (!results && queryError)
        NSLog(@"Search for genome in genebank returned error %@", queryError);

    return [results count];
}

- (NSString*)uniqueNameForSize:(NSUInteger)inSize
{
    NSUInteger  existingSizeCount = [self numberOfGenotypesOfSize:inSize];
    return [NSString stringWithFormat:@"%u%@", inSize, [self identifierFromCount:existingSizeCount]];
}

- (NSString*)identifierFromCount:(NSUInteger)inCount
{
    const NSUInteger kNumDigits = 5;
    
    NSUInteger remainder = inCount;
    
    // make a base 26 string
    unichar     values[kNumDigits];

    for (NSUInteger i = 0; i < kNumDigits - 1; ++i)
    {
        NSUInteger units = 26 * (kNumDigits - 1 - i);
        NSUInteger digit = remainder / units;
        values[i] = 'A' + digit;
        remainder %= units;
    }

    values[kNumDigits - 1] = 'A' + remainder;
    
    return [NSString stringWithCharacters:values length:kNumDigits];
}


#pragma mark -

- (MTGenebankGenotype*)enterGenome:(NSData*)inData name:(NSString*)inName
{
    id newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"Genotype" inManagedObjectContext:mObjectContext];

    [newEntry setValue:inName forKey:@"name"];
    [newEntry setValue:[NSNumber numberWithUnsignedInteger:[inData length]] forKey:@"length"];
    [newEntry setValue:inData forKey:@"genome"];
    return newEntry;
}

#pragma mark -

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
