/*
 *  SerializationTests.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/22/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */


#ifndef SerializationTests_h
#define SerializationTests_h

#include "TestRunner.h"

class SerializationTests : public TestCase
{
public:
    SerializationTests();
    ~SerializationTests();
    
    void setUp();
    void tearDown();

    // tests
    void runTest();

protected:


};


#endif // SerializationTests_h
