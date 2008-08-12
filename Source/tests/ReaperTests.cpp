/*
 *  ReaperTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/11/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "ReaperTests.h"

#include <iostream>

#include "mt_creature.h"
#include "mt_reaper.h"
#include "mt_soup.h"


using namespace MacTierra;


ReaperTests::ReaperTests()
: mSoup(NULL)
{
}


ReaperTests::~ReaperTests()
{
}

void
ReaperTests::setUp()
{
	mSoup = new Soup(1024);
	mReaper = new Reaper();
}

void
ReaperTests::tearDown()
{
	delete mSoup; mSoup = NULL;
	delete mReaper; mReaper = NULL;
}

void
ReaperTests::runTest()
{
	std::cout << "ReaperTests" << std::endl;

	creature_id creatureID = 100;
	Creature*	creature1 = new Creature(++creatureID, mSoup);
	Creature*	creature2 = new Creature(++creatureID, mSoup);

	creature1->setNumErrors(2);
	creature2->setNumErrors(4);
	
	// test empty list
	Creature* head = mReaper->headCreature();
	TEST_CONDITION(!head, "head should be 0");
	
	TEST_CONDITION(!mReaper->conditionalMoveUp(*creature1), "should not have been able to move up");
	TEST_CONDITION(!mReaper->conditionalMoveDown(*creature2), "should not have been able to move down");

	// add to list
	mReaper->addCreature(*creature1);
	mReaper->addCreature(*creature2);
	
	TEST_CONDITION(mReaper->numberOfCreatures() == 2, "should be 2 creatures in the list");
	TEST_CONDITION(mReaper->headCreature() == creature1, "creature 1 should be first");
	
	TEST_CONDITION(mReaper->conditionalMoveUp(*creature2), "should have been able to move up creature 2");
	TEST_CONDITION(mReaper->headCreature() == creature2, "creature 2 should be first");

	creature2->setNumErrors(1);

	TEST_CONDITION(mReaper->conditionalMoveDown(*creature2), "should have been able to move down creature 2");
	TEST_CONDITION(mReaper->headCreature() == creature1, "creature 1 should be first");
}


TestRegistration testReg(new ReaperTests);