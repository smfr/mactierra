//
//  MTInventoryController.h
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


namespace MacTierra {
    class Inventory;
};


@interface MTInventoryController : NSObject
{
    MacTierra::Inventory*   mInventory;
    NSMutableArray*         mGenotypes;
}

- (id)initWithInventory:(MacTierra::Inventory*)inInventory;

- (void)updateGenotypesArray;

- (NSArray*)genotypes;

@end
