//
//  MTInventoryController.h
//  MacTierra
//
//  Created by Simon Fraser on 8/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


namespace MacTierra {
    class Inventory;
};

@interface MTInventoryController : NSObject
{
    NSMutableArray*                 mGenotypes;
}

@property (nonatomic, weak) IBOutlet NSArrayController* genotypesArrayController;
@property (nonatomic, assign) MacTierra::Inventory* inventory;
@property (nonatomic, readonly) NSArray* genotypes;

- (void)updateGenotypesArray;

@end
