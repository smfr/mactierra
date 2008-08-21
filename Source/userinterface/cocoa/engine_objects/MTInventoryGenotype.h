//
//  MTInventoryGenotype.h
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

namespace MacTierra {
    class InventoryGenotype;
};

@interface MTInventoryGenotype : NSObject
{
    MacTierra::InventoryGenotype*       genotype;       // not owned
}

- (id)initWithGenotype:(MacTierra::InventoryGenotype*)inGenotype;

@property (assign) MacTierra::InventoryGenotype* genotype;
@property (readonly) NSString* name;
@property (readonly) NSInteger length;
@property (readonly) NSInteger numAlive;
@property (readonly) NSInteger numEverLived;
@property (readonly) u_int64_t originInstructions;
@property (readonly) NSInteger originGenerations;

@property (readonly) NSString* genotypeString;

@end
