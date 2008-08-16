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

#include "mt_creature.h"
#include "mt_timeslicer.h"
#include "mt_soup.h"
#include "mt_world.h"


using namespace MacTierra;


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
    mSlicer = new TimeSlicer(*mWorld);
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

    Creature*   creature1 = mWorld->createCreature();
    Creature*   creature2 = mWorld->createCreature();
    Creature*   creature3 = mWorld->createCreature();

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

    Creature*   creature4 = mWorld->createCreature();
    // new creature should be added before the current item
    mSlicer->insertCreature(*creature4);

    mSlicer->printCreatures();

    TEST_CONDITION(mSlicer->currentCreature() == creature1);
    mSlicer->removeCreature(*creature1);
    TEST_CONDITION(mSlicer->currentCreature() == creature2);

    mSlicer->printCreatures();

}



TestRegistration slicerTestReg(new SlicerTests);
