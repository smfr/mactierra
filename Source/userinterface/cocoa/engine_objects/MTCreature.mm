//
//  MTCreature.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTCreature.h"

#import "MT_Engine.h"
#import "MT_Creature.h"

#import "MTInventoryGenotype.h"

@implementation MTCreature

- (id)initWithCreature:(MacTierra::Creature*)inCreature
{
    if ((self = [super init]))
    {
        mCreature = inCreature;
    }
    return self;
}

- (void)dealloc
{
    [genotype release];
    
    [super dealloc];
}

- (NSString*)name
{
    return [NSString stringWithUTF8String:mCreature->creatureName().c_str()];
}

- (NSInteger)length
{
    return mCreature->length();
}

- (u_int32_t)location
{
    return mCreature->location();
}

- (MTInventoryGenotype*)genotype
{
    // FIXME: this will get out of sync with the creature's genotype if that is changed
    if (!genotype)
        genotype = [[MTInventoryGenotype alloc] initWithGenotype:mCreature->genotype()];

    return genotype;
}

@end
