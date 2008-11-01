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
    class World;
};

extern NSString* const kCreatureReferencePasteboardType;

@class MTInventoryGenotype;

class CreaturePrivateData;

@interface MTCreature : NSObject
{
    CreaturePrivateData*    mPrivateData;
    
    MTInventoryGenotype*    genotype;
}

+ (id)creatureFromPasteboard:(NSPasteboard*)inPasteboard inWorld:(MacTierra::World*)inWorld;

- (id)initWithCreature:(MacTierra::Creature*)inCreature;

@property (readonly) const MacTierra::Creature* creature;

// we don't even try to make these properties KVC-compliant. Manual updates of the UI are required
@property (readonly) NSString* name;
@property (readonly) NSData* genome;
@property (readonly) NSInteger length;
@property (readonly) NSUInteger location;

@property (readonly) NSInteger instructionPointer;
@property (readonly) NSString* lastInstruction;     // or next one?
@property (readonly) NSString* nextInstruction;
@property (readonly) BOOL flag;

@property (readonly) NSInteger axRegister;
@property (readonly) NSInteger bxRegister;
@property (readonly) NSInteger cxRegister;
@property (readonly) NSInteger dxRegister;

@property (readonly) NSArray* stack;

@property (readonly) NSString* soupAroundIP;
@property (readonly) NSRange soupSelectionRange;

@property (readonly) MTInventoryGenotype* genotype;

@property (readonly) NSDictionary* pasteboardData;

@end
