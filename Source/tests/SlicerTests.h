/*
 *  SlicerTests.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/11/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef SlicerTests_h
#define SlicerTests_h

#include "TestRunner.h"

namespace MacTierra {
class Soup;
class TimeSlicer;
class World;
}

class SlicerTests : public TestCase
{
public:
    SlicerTests();
    ~SlicerTests();
    
    void setUp();
    void tearDown();

    // tests
    void runTest();

protected:

    MacTierra::World*       mWorld;
    MacTierra::TimeSlicer*  mSlicer;

};


#endif // SlicerTests_h
