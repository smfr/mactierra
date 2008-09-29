/*
 *  CellMapTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "CellMapTests.h"


#include <iostream>

#include "MT_Creature.h"
#include "MT_Cellmap.h"
#include "MT_World.h"


using namespace MacTierra;

const u_int32_t kSoupSize = 1024;

CellMapTests::CellMapTests()
: mWorld(NULL)
{
}


CellMapTests::~CellMapTests()
{
}

void
CellMapTests::setUp()
{
    mWorld = new World();
    mWorld->initializeSoup(kSoupSize);

}

void
CellMapTests::tearDown()
{
    delete mWorld; mWorld = NULL;
}

void
CellMapTests::runTest()
{
    std::cout << "CellMapTests" << std::endl;

    RefPtr<Creature>   creature1 = mWorld->createCreature(100);
    creature1->setLocation(100);

    RefPtr<Creature>   creature2 = mWorld->createCreature(100);
    creature2->setLocation(200);

    RefPtr<Creature>   creature3 = mWorld->createCreature(100);
    creature3->setLocation(400);

    // wrapping creature
    RefPtr<Creature>   creature4 = mWorld->createCreature(100);
    creature4->setLocation(1000);

    RefPtr<Creature>   creature5 = mWorld->createCreature(20);
    creature5->setLocation(80);

    TEST_CONDITION(creature1 && creature2 && creature3);

    CellMap*    cellMap = mWorld->cellMap();
    TEST_CONDITION(cellMap);

    // test empty map
    size_t foundIndex = 0;
    TEST_CONDITION(!cellMap->indexOfCreatureAtAddress(0, foundIndex));

    TEST_CONDITION(!cellMap->creatureAtAddress(0));
    TEST_CONDITION(!cellMap->creatureAtAddress(100));

    address_t spaceAddr = 100;
    TEST_CONDITION(cellMap->searchForSpace(spaceAddr, 100, 1024, CellMap::kBothways) && spaceAddr == 100);

    TEST_CONDITION(cellMap->insertCreature(creature1.get()));
    cellMap->printCreatures();

    TEST_CONDITION(cellMap->gapBeforeIndex(0) == (kSoupSize - 100));
    TEST_CONDITION(cellMap->gapAfterIndex(0) == (kSoupSize - 100));

    TEST_CONDITION(cellMap->searchForSpace(spaceAddr, 100, 1024, CellMap::kBothways) && spaceAddr == 200);
    spaceAddr = 99;
    TEST_CONDITION(cellMap->searchForSpace(spaceAddr, 100, 1024, CellMap::kBothways) && spaceAddr == 0);

    TEST_CONDITION(!cellMap->indexOfCreatureAtAddress(99, foundIndex));
    TEST_CONDITION(cellMap->indexOfCreatureAtAddress(100, foundIndex) && foundIndex == 0);
    TEST_CONDITION(cellMap->indexOfCreatureAtAddress(101, foundIndex) && foundIndex == 0);
    TEST_CONDITION(cellMap->indexOfCreatureAtAddress(199, foundIndex) && foundIndex == 0);
    TEST_CONDITION(!cellMap->indexOfCreatureAtAddress(200, foundIndex));
    TEST_CONDITION(!cellMap->indexOfCreatureAtAddress(201, foundIndex));
    TEST_CONDITION(!cellMap->indexOfCreatureAtAddress(1023, foundIndex));

    TEST_CONDITION(cellMap->spaceAtAddress(1020, 6));

    cellMap->printCreatures();

    TEST_CONDITION(!cellMap->creatureAtAddress(0));
    TEST_CONDITION(!cellMap->creatureAtAddress(99));
    TEST_CONDITION(cellMap->creatureAtAddress(100));
    TEST_CONDITION(cellMap->creatureAtAddress(199));
    TEST_CONDITION(!cellMap->creatureAtAddress(200));
    TEST_CONDITION(!cellMap->creatureAtAddress(1023));

    TEST_CONDITION(cellMap->insertCreature(creature4.get()));

    cellMap->printCreatures();

    TEST_CONDITION(cellMap->gapBeforeIndex(0) == (100 - (1100 - kSoupSize)));
    TEST_CONDITION(cellMap->gapAfterIndex(0) == (1000 - 200));

    TEST_CONDITION(cellMap->insertCreature(creature3.get()));
    TEST_CONDITION(cellMap->insertCreature(creature2.get()));

    cellMap->printCreatures();

    TEST_CONDITION(cellMap->gapBeforeIndex(3) == (1000 - 500));
    TEST_CONDITION(cellMap->gapBeforeIndex(2) == 100);

    spaceAddr = 300;
    TEST_CONDITION(cellMap->searchForSpace(spaceAddr, 100, 1024, CellMap::kBothways) && spaceAddr == 300);
    spaceAddr = 1023;
    TEST_CONDITION(cellMap->searchForSpace(spaceAddr, 100, 1024, CellMap::kBothways) && spaceAddr == 900);

    TEST_CONDITION(cellMap->creatureAtAddress(1023));
    TEST_CONDITION(cellMap->creatureAtAddress(0));
    TEST_CONDITION(cellMap->creatureAtAddress(75));
    TEST_CONDITION(!cellMap->creatureAtAddress(76));

    TEST_CONDITION(cellMap->spaceAtAddress(300, 100));
    TEST_CONDITION(!cellMap->spaceAtAddress(300, 101));
    TEST_CONDITION(!cellMap->spaceAtAddress(98, 108));
    TEST_CONDITION(!cellMap->spaceAtAddress(104, 90));
    TEST_CONDITION(!cellMap->spaceAtAddress(1020, 6));
    TEST_CONDITION(!cellMap->spaceAtAddress(2, 4));

    TEST_CONDITION(cellMap->insertCreature(creature5.get()));

    cellMap->printCreatures();

}

TestRegistration cellMapTestReg(new CellMapTests);

