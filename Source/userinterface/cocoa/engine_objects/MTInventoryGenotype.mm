//
//  MTInventoryGenotype.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTInventoryGenotype.h"

#import "MT_Inventory.h"
#include "MT_InstructionSet.h"

using namespace MacTierra;


@implementation MTInventoryGenotype

@synthesize genotype;
@synthesize name;
@synthesize numAlive;
@synthesize numEverLived;
@synthesize originInstructions;
@synthesize originGenerations;
@synthesize genomeString;
@synthesize genome;

+ (NSColorList*)instructionsColorList
{
    static NSColorList* sColorList = nil;
    if (!sColorList)
    {
        NSString* colorListPath = [[NSBundle mainBundle] pathForResource:@"Instructions0" ofType:@"clr"];
        sColorList = [[NSColorList alloc] initWithName:@"Instructions" fromFile:colorListPath];

    }
    return sColorList;
}


- (id)initWithGenotype:(MacTierra::InventoryGenotype*)inGenotype
{
    if ((self = [super init]))
    {
        genotype = inGenotype;
    }
    return self;
}

- (void)dealloc
{
    [mGenotypeImage release];
    [super dealloc];
}

- (NSString*)name
{
    return [NSString stringWithUTF8String:genotype->name().c_str()];
}

- (NSInteger)length
{
    return genotype->length();
}

- (NSInteger)numAlive
{
    return genotype->numberAlive();
}

- (NSInteger)numEverLived
{
    return genotype->numberEverLived();
}

- (u_int64_t)originInstructions
{
    return genotype->originInstructions();
}

- (NSInteger)originGenerations
{
    return genotype->originGenerations();
}

- (NSString*)genomeString
{
    return [NSString stringWithUTF8String:genotype->genome().printableGenome().c_str()];
}

- (NSString*)prettyPrintedGenomeString
{
    NSMutableString* genomeString = [NSMutableString string];
    
    const GenomeData& genome = genotype->genome();

    for (u_int32_t i = 0; i < genome.length(); ++i)
    {
        instruction_t curInst = genome.dataString()[i];
        const char* instructionName = nameForInstruction(curInst);
     
        [genomeString appendFormat:@"%02X %s\n", curInst, instructionName];
    }

    return genomeString;
}

- (NSData*)genome
{
    return [NSData dataWithBytes:genotype->genome().dataString().data() length:genotype->genome().length()];
}

- (NSImage*)genotypeImage
{
    if (mGenotypeImage)
        return mGenotypeImage;

    NSColorList* colorList = [MTInventoryGenotype instructionsColorList];

    NSArray*    colorKeys = [colorList allKeys];
    NSUInteger  numColors = [colorKeys count];

    mGenotypeImage = [[NSImage alloc] initWithSize:NSMakeSize([self length], 1.0f)];
    [mGenotypeImage lockFocus];
    
    const std::string& genomeString = genotype->genome().dataString();
    
    NSInteger len = [self length];
    for (NSInteger i = 0; i < len; ++i)
    {
        instruction_t curInst = genomeString[i];
        curInst = std::min(curInst, (instruction_t)numColors);

        NSString* curKey  = [colorKeys objectAtIndex:curInst];
        NSColor* curColor = [colorList colorWithKey:curKey];

        [curColor set];
        NSRect instRect = NSMakeRect(i, 0, 1, 1);
        NSRectFill(instRect);
    }
    
    [mGenotypeImage unlockFocus];

    return mGenotypeImage;
}

@end
