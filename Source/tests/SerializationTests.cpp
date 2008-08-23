/*
 *  SerializationTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/22/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "SerializationTests.h"

#include <iostream>
#include <fstream>

#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>

#include "MT_Cpu.h"
#include "MT_Creature.h"
#include "MT_Reaper.h"
#include "MT_Soup.h"

using namespace MacTierra;
using namespace std;

SerializationTests::SerializationTests()
{
}


SerializationTests::~SerializationTests()
{
}

void
SerializationTests::setUp()
{
}

void
SerializationTests::tearDown()
{
}

void
SerializationTests::runTest()
{
    cout << "SerializationTests" << endl;

    Cpu theCPU;
    theCPU.push(3);
    theCPU.push(5);
    theCPU.push(6);
    theCPU.push(1);

    theCPU.setFlag();

    theCPU.mInstructionPointer = 12345;


    Soup* theSoup = new Soup(1024);

    instruction_t* soupMem = (instruction_t*)theSoup->soup();
    soupMem[0] = 1;
    soupMem[100] = 2;
    soupMem[200] = 3;
    soupMem[1023] = 5;


    // output archive
    {
        std::ofstream ofs("test.out");

        boost::archive::text_oarchive oa(ofs);
        oa << theCPU;
        oa << theSoup;
    }

    // now read it back in
    Cpu cloneCpu;
    Soup* cloneSoup = NULL;
    {
        std::ifstream ifs("test.out");
        boost::archive::text_iarchive ia(ifs);
        ia >> cloneCpu;
        ia >> cloneSoup;
    }
    TEST_CONDITION(cloneCpu == theCPU);
    TEST_CONDITION(*cloneSoup == *theSoup);



}


TestRegistration serializationTestReg(new SerializationTests);
