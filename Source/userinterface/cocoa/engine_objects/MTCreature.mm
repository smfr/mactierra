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
                return [[MTCreature alloc] initWithCreature:const_cast<Creature*>(foundCreature)];
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

- (NSInteger)numOffspring
{
    return mPrivateData->creature()->numOffspring();
}

- (NSInteger)numIdenticalOffspring
{
    return mPrivateData->creature()->numIdenticalOffspring();
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
    if (!_genotype)
        _genotype = [[MTInventoryGenotype alloc] initWithGenotype:mPrivateData->creature()->genotype()];

    return _genotype;
}

- (MTInventoryGenotype*)parentalGenotype
{
    if (!_parentalGenotype && mPrivateData->creature()->parentalGenotype())  // The first creature in a soup has no parent.
        _parentalGenotype = [[MTInventoryGenotype alloc] initWithGenotype:mPrivateData->creature()->parentalGenotype()];
    
    return _parentalGenotype;
}

- (NSDictionary*)pasteboardData
{
    return [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:mPrivateData->creature()->creatureID()]
                                       forKey:@"creature_id"];
}

@end
