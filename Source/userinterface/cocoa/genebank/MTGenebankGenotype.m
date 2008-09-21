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

@end
