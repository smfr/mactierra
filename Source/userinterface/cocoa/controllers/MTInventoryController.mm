//
//  MTInventoryController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTInventoryController.h"

#import "MT_Inventory.h"

#import "MTInventoryGenotype.h"


using namespace MacTierra;

@implementation MTInventoryController

- (id)initWithInventory:(MacTierra::Inventory*)inInventory
{
    if ((self = [super init]))
    {
        mInventory = inInventory;
    }
    return self;
}

- (void)dealloc
{
    [mGenotypes release];
    [super dealloc];
}

- (void)updateGenotypesArray
{
    [self willChange:NSKeyValueChangeSetting valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [mGenotypes count])] forKey:@"genotypes"];
    
    const Inventory::InventoryMap& theInventory = mInventory->inventoryMap();

    // for now, nuke everything
    [mGenotypes removeAllObjects];
    
    Inventory::InventoryMap::const_iterator it = theInventory.begin();
    Inventory::InventoryMap::const_iterator itEnd = theInventory.end();
    
    while (it != itEnd)
    {
        MacTierra::InventoryGenotype* theGenotype = it->second;
        MTInventoryGenotype* genotypeObj = [[MTInventoryGenotype alloc] initWithGenotype:theGenotype];
    
        [mGenotypes addObject:genotypeObj];
        [genotypeObj release];

        ++it;
    }

    [self didChange:NSKeyValueChangeSetting valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [mGenotypes count])] forKey:@"genotypes"];
}

- (NSArray*)genotypes
{
    const Inventory::InventoryMap& theInventory = mInventory->inventoryMap();

    if (!mGenotypes)
    {
        mGenotypes = [[NSMutableArray alloc] initWithCapacity:theInventory.size()];
        [self updateGenotypesArray];
    }
    
    return mGenotypes;
}

@end
