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

@interface MTGenebankWindowController ( )

@property (nonatomic, weak) IBOutlet NSArrayController* genebankArrayController;

@end

@implementation MTGenebankWindowController

- (MTGenebankController*)genebankController
{
    return [MTGenebankController sharedGenebankController];
}

#pragma mark -

// NSTableView dataSource methods (unused because we bind the columns)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
    // FIXME: for some reason other applications don't want to receive the text drags
    [pasteboard declareTypes:[NSArray arrayWithObjects:kGenotypeDataPasteboardType, NSPasteboardTypeString, nil]  owner:self];

    NSUInteger curIndex = [rowIndexes firstIndex];
    MTGenebankGenotype* curGenotype = [[_genebankArrayController arrangedObjects] objectAtIndex:curIndex];

    MTSerializableGenotype* genotype = [[MTSerializableGenotype alloc] initWithName:curGenotype.name genome:curGenotype.binaryGenome];

    [pasteboard setString:[genotype stringRepresentation] forType:NSPasteboardTypeString];
    [pasteboard setData:[genotype archiveRepresentation] forType:kGenotypeDataPasteboardType];

    return YES;
}



@end
