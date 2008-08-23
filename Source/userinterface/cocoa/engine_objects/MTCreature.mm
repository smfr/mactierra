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

NSString* const kCreaturePasteboardType = @"org.smfr.mactierra.creature";

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

- (NSData*)genome
{
    std::string genomeString = mCreature->genomeString();
    
    NSData* data  = [NSData dataWithBytes:genomeString.data() length:genomeString.length()];
    return data;
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

#pragma mark -

@implementation MTSerializableCreature

@synthesize name;
@synthesize genome;

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.name   = [[decoder decodeObjectForKey:@"name"] retain];
        self.genome = [[decoder decodeObjectForKey:@"genome"] retain];
    }
    return self;
}

- (id)initWithMTCreature:(MTCreature *)inCreature
{
    if ((self = [super init]))
    {
        self.name = inCreature.name;
        self.genome = inCreature.genome;
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

@end
