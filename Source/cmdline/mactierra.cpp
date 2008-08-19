/*
 *  mactierra.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser onMT_A 8/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mactierra.h"

#include "MT_World.h"
#include "MT_Ancestor.h"

using namespace MacTierra;


const int32_t kSoupSize = 4096;
const int32_t kCycleCount = 200;

extern "C" int main()
{
    
    World*  theWorld = new World();
    theWorld->initializeSoup(kSoupSize);

    // seed the soup
    theWorld->insertCreature(1024, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
    
    
    for (int32_t i = 0;i < 2000; ++i)
    {
        theWorld->iterate(kCycleCount);
    }
    
    return 0;
}
