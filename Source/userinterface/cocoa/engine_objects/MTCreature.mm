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
#import "MT_InstructionSet.h"
#import "MT_ISA.h"
#import "MT_World.h"

#import "MTInventoryGenotype.h"

#import "NSCharacterSetAdditions.h"

NSString* const kCreatureDataPasteboardType         = @"org.smfr.mactierra.creature_data";
NSString* const kCreatureReferencePasteboardType    = @"org.smfr.mactierra.creature_ref";

using namespace MacTierra;

class CreaturePrivateData
{
public:
    const MacTierra::Cpu& cpu() const           { return mCreature->cpu(); }
    const MacTierra::Creature* creature() const { return mCreature.get(); }

    RefPtr<MacTierra::Creature> mCreature;
};

@implementation MTCreature

+ (id)creatureFromPasteboard:(NSPasteboard*)inPasteboard inWorld:(World*)inWorld
{
    if ([[inPasteboard types] containsObject:kCreatureReferencePasteboardType])
    {
        NSDictionary* creatureInfo = [inPasteboard propertyListForType:kCreatureReferencePasteboardType];
        NSNumber* creatureIDNum;
        if ((creatureIDNum = [creatureInfo objectForKey:@"creature_id"]))
        {
            creature_id creatureID = (creature_id)[creatureIDNum unsignedIntValue];
        
            const Creature* foundCreature = inWorld->creatureWithID(creatureID);
            if (foundCreature)
                return [[[MTCreature alloc] initWithCreature:const_cast<Creature*>(foundCreature)] autorelease];
        }
    }
    return nil;
}

- (id)initWithCreature:(MacTierra::Creature*)inCreature
{
    if ((self = [super init]))
    {
        mPrivateData = new CreaturePrivateData();
        mPrivateData->mCreature = inCreature;
    }
    return self;
}

- (void)dealloc
{
    delete mPrivateData;
    [genotype release];
    
    [super dealloc];
}

- (const MacTierra::Creature*)creature
{
    return mPrivateData->creature();
}

- (NSString*)name
{
    NSString* name = [NSString stringWithUTF8String:mPrivateData->creature()->creatureName().c_str()];
    if (mPrivateData->creature()->isDead())
        return [name stringByAppendingString:NSLocalizedString(@"DeadCreatureSuffix", @"dead")];

    return name;
}

- (NSData*)genome
{
    std::string genomeString = mPrivateData->creature()->birthGenome().dataString();
    
    return [NSData dataWithBytes:genomeString.data() length:genomeString.length()];
}

- (NSInteger)length
{
    return mPrivateData->creature()->length();
}

- (NSUInteger)location
{
    return mPrivateData->creature()->location();
}

- (NSInteger)instructionPointer
{
    return mPrivateData->cpu().instructionPointer();
}

- (NSString*)lastInstruction
{
    return [NSString stringWithUTF8String:MacTierra::nameForInstruction(mPrivateData->creature()->lastInstruction())];
}

- (NSString*)nextInstruction
{
    MacTierra::instruction_t nextInst = mPrivateData->creature()->getSoupInstruction(mPrivateData->cpu().instructionPointer());
    return [NSString stringWithUTF8String:MacTierra::nameForInstruction(nextInst)];
}

- (BOOL)flag
{
    return mPrivateData->cpu().flag();
}

- (NSInteger)axRegister
{
    return mPrivateData->cpu().registerValue(MacTierra::k_ax);
}

- (NSInteger)bxRegister
{
    return mPrivateData->cpu().registerValue(MacTierra::k_bx);
}

- (NSInteger)cxRegister
{
    return mPrivateData->cpu().registerValue(MacTierra::k_cx);
}

- (NSInteger)dxRegister
{
    return mPrivateData->cpu().registerValue(MacTierra::k_dx);
}

- (NSArray*)stack
{
    NSMutableArray*    stackArray = [NSMutableArray arrayWithCapacity:MacTierra::kStackSize];
    int32_t stackPointer = mPrivateData->cpu().stackPointer();
    for (u_int32_t i = 0; i < MacTierra::kStackSize; ++i)
    {
        NSDictionary* stackItem = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInteger:mPrivateData->cpu().stackValue(i)], @"value",
                                        ((i == stackPointer) ? @"•" : @"") , @"sp",
                                        nil];
        [stackArray addObject:stackItem];
    }
    return stackArray;
}

- (NSArray*)stackPointer
{
    return [NSArray array];
}

const NSInteger kSoupVisibleRange = 48;
const NSInteger kRangeBeforeIP = 8;

- (NSString*)soupAroundIP
{
    NSMutableString* soupString = [NSMutableString stringWithCapacity:3 * kSoupVisibleRange];

    for (int32_t i = 0; i < kSoupVisibleRange; ++i)
    {
        int32_t offset = mPrivateData->cpu().instructionPointer() + i - kRangeBeforeIP;
        MacTierra::instruction_t curInst = mPrivateData->creature()->getSoupInstruction(offset);
        [soupString appendFormat:@"%02X ", curInst];
    }

    return soupString;
}

- (NSRange)soupSelectionRange
{
    return NSMakeRange(3 * kRangeBeforeIP, 2);
}

- (MTInventoryGenotype*)genotype
{
    // FIXME: this will get out of sync with the creature's genotype if that is changed
    if (!genotype)
        genotype = [[MTInventoryGenotype alloc] initWithGenotype:mPrivateData->creature()->genotype()];

    return genotype;
}

- (NSDictionary*)pasteboardData
{
    return [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:mPrivateData->creature()->creatureID()]
                                       forKey:@"creature_id"];
}

@end


#pragma mark -

@implementation MTSerializableCreature

@synthesize name;
@synthesize genome;

+ (id)serializableCreatureFromPasteboard:(NSPasteboard*)inPasteboard
{
    MTSerializableCreature* creature = nil;
    
    if ([[inPasteboard types] containsObject:kCreatureDataPasteboardType])
    {
        NSData* creatureData = [inPasteboard dataForType:kCreatureDataPasteboardType];
        if (creatureData)
            creature = [NSKeyedUnarchiver unarchiveObjectWithData:creatureData];
    }
    else if ([[inPasteboard types] containsObject:NSStringPboardType])
    {
        NSString* pasteboardString = [inPasteboard stringForType:NSStringPboardType];
        if (pasteboardString)
            creature = [MTSerializableCreature serializableCreatureFromString:pasteboardString];
    }

    return creature;
}

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

+ (id)serializableCreatureFromString:(NSString*)inString
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

        return [[[MTSerializableCreature alloc] initWithName:creatureName genome:genomeData] autorelease];
    }
    return nil;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.name   = [[decoder decodeObjectForKey:@"name"] retain];
        self.genome = [[decoder decodeObjectForKey:@"genome"] retain];
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
