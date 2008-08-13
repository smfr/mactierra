/*
 *  ReaperTests.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/11/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef ReaperTests_h
#define ReaperTests_h

#include "TestRunner.h"

namespace MacTierra {
class Soup;
class Reaper;
}

class ReaperTests : public TestCase
{
public:
    ReaperTests();
    ~ReaperTests();
    
    void setUp();
    void tearDown();

    // tests
    void runTest();

protected:

    MacTierra::Soup*        mSoup;
    MacTierra::Reaper*      mReaper;

};


#endif // ReaperTests_h
