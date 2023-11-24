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

extern NSString* const kGenotypeDataPasteboardType;

@interface MTInventoryGenotype : NSObject
{
    NSImage* _genotypeImage;
}

- (id)initWithGenotype:(MacTierra::InventoryGenotype*)inGenotype;

@property (assign) MacTierra::InventoryGenotype* genotype;
@property (readonly) NSString* name;
@property (readonly) NSInteger length;
@property (readonly) NSInteger numAlive;
@property (readonly) NSInteger numEverLived;
@property (readonly) u_int64_t originInstructions;
@property (readonly) NSInteger originGenerations;

@property (readonly) NSString* genomeString;        // like "01 01 0a" etc.
@property (readonly) NSString* prettyPrintedGenomeString;        // pretty-printed
@property (readonly) NSData* genome;

@property (readonly) NSImage* genotypeImage;

@end


@class MTCreature;

// Put onto the pasteboard with type kGenotypeDataPasteboardType
@interface MTSerializableGenotype : NSObject<NSCoding>
{
}

@property (retain) NSString* name;
@property (retain) NSData* genome;

+ (id)serializableGenotypeFromString:(NSString*)inString;
+ (id)serializableGenotypeFromPasteboard:(NSPasteboard*)inPasteboard;
+ (id)serializableGenotypeFromCreature:(MTCreature*)inCreature;
+ (id)serializableGenotypeFromGenotype:(MTInventoryGenotype*)inGenotype;

- (id)initWithCoder:(NSCoder *)decoder;
- (id)initWithName:(NSString *)inName genome:(NSData*)inGenome;

- (NSData*)archiveRepresentation;
- (NSString*)stringRepresentation;

@end
