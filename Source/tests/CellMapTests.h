/*
 *  CellMapTests.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef CellMapTests_h
#define CellMapTests_h

#include "TestRunner.h"

namespace MacTierra {
class World;
}

class CellMapTests : public TestCase
{
public:
    CellMapTests();
    ~CellMapTests();
    
    void setUp();
    void tearDown();

    // tests
    void runTest();

protected:

    MacTierra::World*       mWorld;

};


#endif // ReaperTests_h
