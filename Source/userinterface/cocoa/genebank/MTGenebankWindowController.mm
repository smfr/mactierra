//
//  MTGenebankWindowController.m
//  MacTierra
//
//  Created by Simon Fraser on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTGenebankWindowController.h"

#import "MTCreature.h"
#import "MTGenebankGenotype.h"
#import "MTGenebankController.h"

@implementation MTGenebankWindowController

- (MTGenebankController*)genebankController
{
    return [MTGenebankController sharedGenebankController];
}

#pragma mark -

// NSTableView dataSource methods (unused because we bind the columns)
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
    [pasteboard declareTypes:[NSArray arrayWithObject:kCreaturePasteboardType]  owner:self];

    NSUInteger curIndex = [rowIndexes firstIndex];
    MTGenebankGenotype* curGenotype = [[mGenebankArrayController arrangedObjects] objectAtIndex:curIndex];

    MTSerializableCreature* curCreature = [[[MTSerializableCreature alloc] initWithName:curGenotype.name genome:curGenotype.binaryGenome] autorelease];
    NSData* creatureData = [NSKeyedArchiver archivedDataWithRootObject:curCreature]; 
    [pasteboard setData:creatureData forType:kCreaturePasteboardType];
    return YES;
}



@end
