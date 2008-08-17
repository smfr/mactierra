/*
 *  CPUTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/16/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <iostream>

#include "CPUTests.h"

#include "mt_ancestor.h"
#include "mt_cpu.h"
#include "mt_soup.h"
#include "mt_world.h"

using namespace MacTierra;
using namespace std;

const u_int32_t kSoupSize = 1024;

CPUTests::CPUTests()
: mWorld(NULL)
{
}


CPUTests::~CPUTests()
{
}

void
CPUTests::setUp()
{
    mWorld = new World();
    mWorld->initializeSoup(kSoupSize);
}

void
CPUTests::tearDown()
{
    delete mWorld; mWorld = NULL;
}

void
CPUTests::runTest()
{
    std::cout << "CPUTests" << std::endl;
    
    Creature* creature = mWorld->insertCreature(100, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));

    mWorld->iterate(1);
}

TestRegistration cpuTestReg(new CPUTests);
