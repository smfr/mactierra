//
//  MTCreature.h
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

namespace MacTierra {
    class Creature;
};

extern NSString* const kCreaturePasteboardType;

@class MTInventoryGenotype;

@interface MTCreature : NSObject
{
    MacTierra::Creature*    mCreature;
    
    MTInventoryGenotype*    genotype;
}

- (id)initWithCreature:(MacTierra::Creature*)inCreature;

@property (readonly) NSString* name;
@property (readonly) NSData* genome;
@property (readonly) NSInteger length;
@property (readonly) u_int32_t location;

@property (readonly) MTInventoryGenotype* genotype;

@end


@interface MTSerializableCreature : NSObject<NSCoding>
{
    NSString*       name;
    NSData*         genome;
}

@property (retain) NSString* name;
@property (retain) NSData* genome;

- (id)initWithCoder:(NSCoder *)decoder;
- (id)initWithMTCreature:(MTCreature *)inCreature;

@end
