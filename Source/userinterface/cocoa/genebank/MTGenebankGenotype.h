//
//  Genotype.h
//  MacTierra
//
//  Created by Simon Fraser on 9/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface MTGenebankGenotype :  NSManagedObject  
{
}

@property (retain) NSString* name;
@property (retain) NSNumber* length;
@property (retain) NSString* genome;    // looks like "01011F...". Has to be string for indexing

@property (readonly) NSString* readableGenomeString;        // like "01 01 1F ..."
@property (readonly) NSData* binaryGenome;

@end


