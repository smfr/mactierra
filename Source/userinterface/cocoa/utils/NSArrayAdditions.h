//
//  NSArrayAdditions.h
//  MacTierra
//
//  Created by Simon Fraser on 12/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray(MTArrayAdditions)

- (id)firstObject;

- (NSArray*)arrayByRemovingObjectsInArray:(NSArray*)inOtherArray;
- (NSArray*)arrayByRemovingObjectsNotInArray:(NSArray*)inOtherArray;

// return an array of the values of the objects in the receiver for the given key.
- (NSArray*)arrayWithValuesForKey:(NSString*)inKey;

@end

@interface NSMutableArray(MTMutableArrayAdditions)

//- (void)setObjectsInRange:(NSRange)inRange toObject:(id)inObject;

// assumes the array is already sorted using the same comparator
// returns index of inserted object
- (NSInteger)insertObject:(id)inObject sortedUsingSelector:(SEL)comparator;

// binary search for an object in a sorted array. Returns NSNotFound on failure.
- (NSUInteger)indexOfObject:(id)object sortedUsingSelector:(SEL)comparator;

@end
