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
@property (readonly) NSUInteger location;

// cpu properties
@property (readonly) NSInteger instructionPointer;
@property (readonly) NSString* lastInstruction;     // or next one?
@property (readonly) BOOL flag;

@property (readonly) NSInteger axRegister;
@property (readonly) NSInteger bxRegister;
@property (readonly) NSInteger cxRegister;
@property (readonly) NSInteger dxRegister;

@property (readonly) NSArray* stack;

@property (readonly) NSString* soupAroundIP;
@property (readonly) NSRange soupSelectionRange;


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
- (id)initWithName:(NSString *)inName genome:(NSData*)inGenome;

@end
