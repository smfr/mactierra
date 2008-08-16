/*
 *  mactierra.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mactierra.h"

#include "mt_world.h"

using namespace MacTierra;


const int32_t kSoupSize = 4096;
const int32_t kCycleCount = 200;

extern "C" int main()
{
    
    World*  theWorld = new World();
    theWorld->initializeSoup(kSoupSize);

    for (int32_t i = 0;i < 2000; ++i)
    {
        theWorld->iterate(kCycleCount);
    }
    
    return 0;
}
