//
//  NSArrayAdditions.m
//  MacTierra
//
//  Created by Simon Fraser on 12/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSArrayAdditions.h"


@implementation NSArray(MTArrayAdditions)

- (id)firstObject
{
    return ([self count] > 0) ? [self objectAtIndex:0] : nil;
}

- (NSArray*)arrayByRemovingObjectsInArray:(NSArray*)inOtherArray
{
	NSMutableArray* trimmedArray = [[self mutableCopy] autorelease];
	[trimmedArray removeObjectsInArray:inOtherArray];
	return trimmedArray;
}

- (NSArray*)arrayByRemovingObjectsNotInArray:(NSArray*)inOtherArray
{
	NSMutableArray* trimmedArray = [[self mutableCopy] autorelease];

	// is there a more efficient way?
	for (id curObject in self)
	{
		if (![inOtherArray containsObject:curObject])
			[trimmedArray removeObject:curObject];
	}
	
	return trimmedArray;
}

- (NSArray*)arrayWithValuesForKey:(NSString*)inKey
{
    NSMutableArray*   valuesArray = [NSMutableArray arrayWithCapacity:[self count]];
    
    for (id curItem in self)
    {
        id val = [curItem valueForKey:inKey];
        [valuesArray addObject:val];
    }
    
    return valuesArray;
}

@end

@implementation NSMutableArray(MTMutableArrayAdditions)

- (NSInteger)insertObject:(id)inObject sortedUsingSelector:(SEL)comparator
{
    NSInteger   length = [self count];
    if (length == 0)
    {
        [self addObject:inObject];
        return 0;
    }
    
    NSInteger high = length;
    NSInteger low  = 0;
    NSInteger  mid = 0;
    
    while (high > low)
    {
        mid = (low + high) / 2;
        
        id testObject = [self objectAtIndex:mid];

		NSComparisonResult order = (NSComparisonResult)[testObject performSelector:comparator withObject:inObject];
		switch (order)
		{
			case NSOrderedAscending:
			    // our item comes after testObject
			    low = mid + 1;
			    break;
			    
			case NSOrderedDescending:
			    // our item comes before testObject
			    high = mid - 1;
			    break;
        
            case NSOrderedSame:
                // uh oh, items not unique
				[[NSException exceptionWithName:@"SortCollision" reason:@"Items not unique in sorted array" userInfo:nil] raise];
                break;
        }
    }

	[self insertObject:inObject atIndex:mid];
    return mid;
}

- (NSUInteger)indexOfObject:(id)inObject sortedUsingSelector:(SEL)comparator
{
    NSInteger high = [self count];
    NSInteger low  = 0;

    while (high > low)
    {
        NSInteger   mid = (high - low) / 2;
        
        id testObject = [self objectAtIndex:mid];

		NSComparisonResult order = (NSComparisonResult)[testObject performSelector:comparator withObject:inObject];
		switch (order)
		{
			case NSOrderedAscending:
			    // our item comes after testObject
			    low = mid + 1;
			    break;
			    
			case NSOrderedDescending:
			    // our item comes before testObject
			    high = mid - 1;
			    break;
        
            case NSOrderedSame:
                return mid;
                break;
        }
    }

    return NSNotFound;
}

@end

