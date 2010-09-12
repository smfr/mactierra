/*
 *  SoupTests.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 9/12/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "TestRunner.h"

namespace MacTierra {
class Soup;
}

class SoupTests : public TestCase
{
public:
    SoupTests();
    ~SoupTests();
    
    void setUp();
    void tearDown();

    // tests
    void runTest();

protected:
    
    void testPowerOfTwoSoup();
    void testNonPowerOfTwoSoup();

    void runTemplateTests(u_int32_t soupSize);
    void runTemplateAtStartTests(u_int32_t soupSize);
    void runWrappedSearchTests(u_int32_t soupSize);
    void runEndConditionTests(u_int32_t soupSize);
    
protected:

    MacTierra::Soup*       mSoup;

};

