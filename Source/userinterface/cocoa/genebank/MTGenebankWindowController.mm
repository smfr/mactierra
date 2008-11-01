//
//  MTGenebankWindowController.m
//  MacTierra
//
//  Created by Simon Fraser on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTGenebankWindowController.h"

#import "MTInventoryGenotype.h"
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
    // FIXME: for some reason other applications don't want to receive the text drags
    [pasteboard declareTypes:[NSArray arrayWithObjects:kGenotypeDataPasteboardType, NSStringPboardType, nil]  owner:self];

    NSUInteger curIndex = [rowIndexes firstIndex];
    MTGenebankGenotype* curGenotype = [[mGenebankArrayController arrangedObjects] objectAtIndex:curIndex];

    MTSerializableGenotype* genotype = [[[MTSerializableGenotype alloc] initWithName:curGenotype.name genome:curGenotype.binaryGenome] autorelease];

    [pasteboard setString:[genotype stringRepresentation] forType:NSStringPboardType];
    [pasteboard setData:[genotype archiveRepresentation] forType:kGenotypeDataPasteboardType];

    return YES;
}



@end
