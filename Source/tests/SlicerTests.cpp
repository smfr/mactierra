/*
 *  SlicerTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/11/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "SlicerTests.h"

#include <iostream>

#define HAVE_BOOST_SERIALIZATION 1
#include "RandomLib/Random.hpp"
#include "RandomLib/ExponentialDistribution.hpp"

#include "MT_Creature.h"
#include "MT_Timeslicer.h"
#include "MT_Soup.h"
#include "MT_World.h"


using namespace MacTierra;
using namespace std;

SlicerTests::SlicerTests()
: mWorld(NULL)
, mSlicer(NULL)
{
}


SlicerTests::~SlicerTests()
{
}

void
SlicerTests::setUp()
{
    mWorld = new World();
    mWorld->initializeSoup(1024);
    mSlicer = new TimeSlicer(mWorld);
}

void
SlicerTests::tearDown()
{
    delete mSlicer; mSlicer = NULL;
    delete mWorld; mWorld = NULL;
}

void
SlicerTests::runTest()
{
    std::cout << "SlicerTests" << std::endl;

    RefPtr<Creature>   creature1 = mWorld->createCreature();
    RefPtr<Creature>   creature2 = mWorld->createCreature();
    RefPtr<Creature>   creature3 = mWorld->createCreature();

    TEST_CONDITION(creature1 && creature2 && creature3);
    TEST_CONDITION(!mSlicer->currentCreature());
    
    mSlicer->insertCreature(*creature1);
    mSlicer->insertCreature(*creature2);
    mSlicer->insertCreature(*creature3);

    // should be 2, 3, 1 at this point
    mSlicer->printCreatures();
    
    TEST_CONDITION(mSlicer->currentCreature() == creature1);

    TEST_CONDITION(mSlicer->advance());
    mSlicer->printCreatures();
    TEST_CONDITION(mSlicer->currentCreature() == creature2);

    TEST_CONDITION(!mSlicer->advance());
    mSlicer->printCreatures();
    TEST_CONDITION(mSlicer->currentCreature() == creature3);

    TEST_CONDITION(!mSlicer->advance());
    mSlicer->printCreatures();
    TEST_CONDITION(mSlicer->currentCreature() == creature1);

    RefPtr<Creature>   creature4 = mWorld->createCreature();
    // new creature should be added before the current item
    mSlicer->insertCreature(*creature4);

    mSlicer->printCreatures();

    TEST_CONDITION(mSlicer->currentCreature() == creature1);
    mSlicer->removeCreature(*creature1);
    TEST_CONDITION(mSlicer->currentCreature() == creature2);

    mSlicer->printCreatures();

    RefPtr<Creature>   testCreature = mWorld->createCreature();
    testCreature->setLocation(100);

    const double kSliceSizeVariance = 1;
    cout << "Slice sizes" << endl;
    for (u_int32_t i = 20; i < 1000; ++i)
    {
        testCreature->setLength(i);
        testCreature->setSliceSize(mSlicer->initialSliceSizeForCreature(testCreature.get(), mWorld->settings()));
        cout << "Length " << i << ": " << testCreature->sliceSize() << " actual:" << mSlicer->sizeForThisSlice(testCreature.get(), kSliceSizeVariance) << endl;
    }


}



TestRegistration slicerTestReg(new SlicerTests);
