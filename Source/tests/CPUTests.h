/*
 *  CPUTests.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/16/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef CPUTests_h
#define CPUTests_h

#include "TestRunner.h"

namespace MacTierra {
class World;
}

class CPUTests : public TestCase
{
public:
    CPUTests();
    ~CPUTests();
    
    void setUp();
    void tearDown();

    // tests
    void runTest();

protected:

    MacTierra::World*        mWorld;

};


#endif // CPUTests_h
