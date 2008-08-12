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

ReaperTests::ReaperTests()
{
}


ReaperTests::~ReaperTests()
{
}

void
ReaperTests::setUp()
{
}

void
ReaperTests::tearDown()
{
}

void
ReaperTests::runTest()
{
	std::cout << "testReaperList" << std::endl;
}


TestRegistration testReg(new ReaperTests);