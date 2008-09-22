// 
//  Genotype.m
//  MacTierra
//
//  Created by Simon Fraser on 9/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTGenebankGenotype.h"


@implementation MTGenebankGenotype

@dynamic name;
@dynamic length;
@dynamic genome;

+ (NSSet *)keyPathsForValuesAffectingReadableGenomeString
{
    return [NSSet setWithObjects:@"genome", nil];
}

- (NSString*)readableGenomeString
{
    NSString* theGenome = self.genome;
    NSUInteger genomeLen = [theGenome length] / 2;

    NSMutableString* theString = [NSMutableString stringWithCapacity:3 * genomeLen];
    
    NSUInteger i;
    for (i = 0; i < genomeLen; ++i)
    {
        if (i > 0)
            [theString appendString:@" "];

        [theString appendString:[theGenome substringWithRange:NSMakeRange(2 * i, 2)]];
    }

    return theString;
}

- (NSData*)binaryGenome
{
    NSString* theGenome = self.genome;
    NSUInteger genomeLen = [theGenome length] / 2;

    NSMutableData*  genomeData = [NSMutableData dataWithLength:genomeLen];
    
    unsigned char* dataBytes = (unsigned char*)[genomeData mutableBytes];
    
    for (NSUInteger i = 0; i < genomeLen; ++i)
    {
        unichar char1 = tolower([theGenome characterAtIndex:2 * i]);
        unichar char2 = tolower([theGenome characterAtIndex:2 * i + 1]);

        u_int32_t charVal1 = (char1 < 'a') ? char1 - '0' : char1 - ('a' - 10);
        u_int32_t charVal2 = (char2 < 'a') ? char2 - '0' : char2 - ('a' - 10);

        dataBytes[i] = ((charVal1 & 0x0F) << 4) | (charVal2 & 0x0F);
    }
    
    return genomeData;
}

@end
