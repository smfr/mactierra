//
//  MTInventoryController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTInventoryController.h"

#import "MT_Inventory.h"

#import "MTCreature.h"
#import "MTInventoryGenotype.h"


using namespace MacTierra;

@implementation MTInventoryController

@synthesize inventory;

- (void)dealloc
{
    [mGenotypes release];
    [super dealloc];
}

- (void)setInventory:(MacTierra::Inventory*)inInventory
{
    if (inInventory != inventory)
    {
        [mGenotypes release];
        mGenotypes = nil;
        
        inventory = inInventory;
    }
}

- (void)updateGenotypesArray
{
    if (!inventory)
        return;

    [self willChange:NSKeyValueChangeSetting valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [mGenotypes count])] forKey:@"genotypes"];
    
    const Inventory::InventoryMap& theInventory = inventory->inventoryMap();

    if (!mGenotypes)
    {
        mGenotypes = [[NSMutableArray alloc] initWithCapacity:theInventory.size()];
    }
    else
    {
        // for now, nuke everything
        [mGenotypes removeAllObjects];
    }
    
    Inventory::InventoryMap::const_iterator it = theInventory.begin();
    Inventory::InventoryMap::const_iterator itEnd = theInventory.end();
    
    while (it != itEnd)
    {
        MacTierra::InventoryGenotype* theGenotype = it->second;
        // only show current genotypes, for performance
        if (theGenotype->numberAlive() > 0)
        {
            MTInventoryGenotype* genotypeObj = [[MTInventoryGenotype alloc] initWithGenotype:theGenotype];
        
            [mGenotypes addObject:genotypeObj];
            [genotypeObj release];
        }
        ++it;
    }

    [self didChange:NSKeyValueChangeSetting valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [mGenotypes count])] forKey:@"genotypes"];
}

- (NSArray*)genotypes
{
    if (!inventory)
        return [NSArray array];

    if (!mGenotypes)
        [self updateGenotypesArray];
    
    return mGenotypes;
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
    [pasteboard declareTypes:[NSArray arrayWithObjects:kCreaturePasteboardType, NSStringPboardType, nil]  owner:self];

    NSUInteger curIndex = [rowIndexes firstIndex];
    MTInventoryGenotype* curGenotype = [[mGenotypesArrayController arrangedObjects] objectAtIndex:curIndex];

    MTSerializableCreature* curCreature = [[[MTSerializableCreature alloc] initWithName:[curGenotype name] genome:[curGenotype genome]] autorelease];

    [pasteboard setString:[curCreature stringRepresentation] forType:NSStringPboardType];
    [pasteboard setData:[curCreature archiveRepresentation] forType:kCreaturePasteboardType];

    return true;
}


@end
