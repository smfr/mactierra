//
//  MTInventoryGenotype.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSCharacterSetAdditions.h"

#import "MT_Inventory.h"
#import "MT_InstructionSet.h"

#import "MTCreature.h"
#import "MTInventoryGenotype.h"

using namespace MacTierra;

NSString* const kGenotypeDataPasteboardType         = @"org.smfr.mactierra.genotype_data";

@implementation MTInventoryGenotype

@synthesize genotype;

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
    NSAssert(inGenotype, @"initWithGenotype called with null genotype");
    if (!inGenotype) {
        [self release];
        return nil;
    }
        
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
    NSMutableString* genomeStr = [NSMutableString string];
    
    const GenomeData& genomeData = genotype->genome();

    for (u_int32_t i = 0; i < genomeData.length(); ++i)
    {
        instruction_t curInst = genomeData.dataString()[i];
        const char* instructionName = nameForInstruction(curInst);
     
        [genomeStr appendFormat:@"%02X %s\n", curInst, instructionName];
    }

    return genomeStr;
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
    
    const std::string& genomeStr = genotype->genome().dataString();
    
    NSInteger len = [self length];
    for (NSInteger i = 0; i < len; ++i)
    {
        instruction_t curInst = genomeStr[i];
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



#pragma mark -

@implementation MTSerializableGenotype

@synthesize name;
@synthesize genome;

static BOOL isValidInstructionString(NSString* inString)
{
    NSCharacterSet* hexSet = [NSCharacterSet hexCharacterSet];
    
    return [inString length] == 2 &&
            [hexSet characterIsMember:[inString characterAtIndex:0]] &&
            [hexSet characterIsMember:[inString characterAtIndex:1]];
}

static unsigned char instructionFromString(NSString* inString)
{
    NSString* curWord = [inString lowercaseString];
    unichar char1 = [curWord characterAtIndex:0];
    unichar char2 = [curWord characterAtIndex:1];

    u_int32_t charVal1 = (char1 < 'a') ? char1 - '0' : char1 - ('a' - 10);
    u_int32_t charVal2 = (char2 < 'a') ? char2 - '0' : char2 - ('a' - 10);

    return ((charVal1 & 0x0F) << 4) | (charVal2 & 0x0F);
}

static NSData* genomeDataFromSingleLineGenomeString(NSString* inString, NSString** outName)
{
    NSArray*        lineWords = [inString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableData*  genomeData = [NSMutableData data];
    
    if (outName)
        *outName = nil;

    unsigned i, numWords = [lineWords count];
    if (numWords < 3)
        return nil;
    for (i = 0; i < numWords; ++i)
    {
        NSString* curWord = [lineWords objectAtIndex:i];

        if (!isValidInstructionString(curWord))
        {
            if (i == 0)
            {
                if (outName)
                    *outName = curWord;
                continue;
            }
            else if ([curWord length] == 0 || [curWord isEqualToString:@"\n"])
                break;
            else
                return nil; // invalid
        }
        
        unsigned char curInst = instructionFromString(curWord);
        [genomeData appendBytes:&curInst length:1];
    }

    return genomeData;
}

+ (id)serializableGenotypeFromString:(NSString*)inString
{
    /* We accept two formats:
    
        1. A list of space-separated hex values, like:
            1d 01 01 06 1e 02 01 1f 1a 0a 05 14 00 08 09 15 00 01 1f 11 17 00 00
        
            It may have an optional name prefix:
            
            23aab 1d 01 01 06 1e 02 01 00 1a 0a 05 14 00 08 09 15 00 01 1f 11 17 00 00
            
        2. An optional name, followed by one instruction per line with optional trailing data:
        
            23aaa
            1D adrf
            00 nop_0
            00 nop_0
            06 sub_ab
            1E mal
            01 nop_1
            00 nop_0

        In both cases, lines starting with # are treated as comments
    */

    NSArray* lines = [inString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSData* genomeData = nil;
    NSString* creatureName = nil;

    // try the first form
    for (NSString* curLine in lines)
    {
        if ([curLine hasPrefix:@"#"])
            continue;
        
        genomeData = genomeDataFromSingleLineGenomeString(curLine, &creatureName);
        if (genomeData)
            break;
    }
    
    // try the second form
    if (!genomeData)
    {
        NSMutableData* mutableGenome = [NSMutableData data];
        
        unsigned i, numLines = [lines count];
        for (i = 0; i < numLines; ++i)
        {
            NSString* curLine = [lines objectAtIndex:i];
            if ([curLine hasPrefix:@"#"] || [curLine length] == 0)
                continue;
            
            // first line may be name
            NSRange whitespaceRange = [curLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
            unsigned wordEnd = (whitespaceRange.location != NSNotFound) ? whitespaceRange.location : [curLine length];

            if ([mutableGenome length] == 0 && wordEnd > 2)
            {
                creatureName = curLine;
            }
            else if (wordEnd == 2 && isValidInstructionString([curLine substringToIndex:2]))
            {
                unsigned char curInst = instructionFromString(curLine);
                [mutableGenome appendBytes:&curInst length:1];
            }
            else
            {
                // bad instruction; bail
                mutableGenome = nil;
                break;
            }
        }
        
        genomeData = mutableGenome;
    }
    
    if (genomeData)
    {
        if (!creatureName)
            creatureName = [NSString stringWithFormat:@"%daaaaa", [genomeData length]];

        return [[[MTSerializableGenotype alloc] initWithName:creatureName genome:genomeData] autorelease];
    }
    return nil;
}

+ (id)serializableGenotypeFromPasteboard:(NSPasteboard*)inPasteboard
{
    MTSerializableGenotype* creature = nil;
    
    if ([[inPasteboard types] containsObject:kGenotypeDataPasteboardType])
    {
        NSData* creatureData = [inPasteboard dataForType:kGenotypeDataPasteboardType];
        if (creatureData)
            creature = [NSKeyedUnarchiver unarchiveObjectWithData:creatureData];
    }
    else if ([[inPasteboard types] containsObject:NSStringPboardType])
    {
        NSString* pasteboardString = [inPasteboard stringForType:NSStringPboardType];
        if (pasteboardString)
            creature = [MTSerializableGenotype serializableGenotypeFromString:pasteboardString];
    }

    return creature;
}

+ (id)serializableGenotypeFromCreature:(MTCreature*)inCreature
{
    return [[[MTSerializableGenotype alloc] initWithName:inCreature.name genome:inCreature.genome] autorelease];
}

+ (id)serializableGenotypeFromGenotype:(MTInventoryGenotype*)inGenotype
{
    return [[[MTSerializableGenotype alloc] initWithName:inGenotype.name genome:inGenotype.genome] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.name   = [decoder decodeObjectForKey:@"name"];
        self.genome = [decoder decodeObjectForKey:@"genome"];
    }
    return self;
}

- (id)initWithName:(NSString *)inName genome:(NSData*)inGenome
{
    if ((self = [super init]))
    {
        self.name = [[inName copy] autorelease];
        self.genome = [[inGenome copy] autorelease];
    }
    return self;
}

- (void)dealloc
{
    self.name = nil;
    self.genome = nil;
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:name forKey:@"name"];
    [encoder encodeObject:genome forKey:@"genome"];
}

- (NSData*)archiveRepresentation
{
    return [NSKeyedArchiver archivedDataWithRootObject:self]; 
}

// FIXME: there are too many places that convert between genome data and strings. Need to share the code.
- (NSString*)stringRepresentation
{
    NSMutableString* genomeString = [NSMutableString string];

    [genomeString appendFormat:@"%@\n", name];
    
    const unsigned char* genomeBytes = (const unsigned char*)[self.genome bytes];

    for (u_int32_t i = 0; i < [genome length]; ++i)
    {
        unsigned char curInst = genomeBytes[i];
        const char* instructionName = MacTierra::nameForInstruction(curInst);
     
        [genomeString appendFormat:@"%02X %s\n", curInst, instructionName];
    }

    return genomeString;
}

@end
    