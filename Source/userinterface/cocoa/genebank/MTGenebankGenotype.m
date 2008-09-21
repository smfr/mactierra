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

+ (NSSet *)keyPathsForValuesAffectingGenomeString
{
    return [NSSet setWithObjects:@"genome", nil];
}

- (NSString*)genomeString
{
    NSData* theGenome = self.genome;
    NSUInteger dataLen = [theGenome length];

    NSMutableString* theString = [NSMutableString stringWithCapacity:dataLen * 3];
    
    unsigned char* genomeBytes = (unsigned char*)[theGenome bytes];
    NSUInteger i;
    for (i = 0; i < dataLen; ++i)
    {
        if (i > 0)
            [theString appendString:@" "];

        [theString appendFormat:@"%02X", genomeBytes[i]];
    }

    return theString;
}

@end
