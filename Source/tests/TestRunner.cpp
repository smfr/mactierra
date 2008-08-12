/*
 *  TestRunner.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/11/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "TestRunner.h"

#include <iostream>

using namespace std;

TestRegistrar* TestRegistrar::gRegistrar = NULL;

TestRegistrar::TestRegistrar()
{
}

TestRegistrar::~TestRegistrar()
{
	for (TestList::iterator it = mTestList.begin(); it != mTestList.end(); ++it)
		delete (*it);

	mTestList.clear();
}

TestRegistrar::TestList&
TestRegistrar::testList()
{
	return mTestList;
}

void
TestRegistrar::addTest(TestCase* inTest)
{
	mTestList.push_back(inTest);
}

/* static */
TestRegistrar*
TestRegistrar::testRegistrar()
{
	if (!gRegistrar)
		gRegistrar = new TestRegistrar();

	return gRegistrar;
}

/* static */
void
TestRegistrar::deleteRegistrar()
{
	delete gRegistrar;
}

extern "C" int main()
{
	cout << "Starting tests..." << endl;


	TestRegistrar::TestList& tests = TestRegistrar::testRegistrar()->testList();

	for (TestRegistrar::TestList::iterator it = tests.begin(); it != tests.end(); ++it)
	{
		TestCase*	testCase = (*it);
		testCase->setUp();
		testCase->runTest();
		testCase->tearDown();
	}

	cout << "Finished tests" << endl;
	return 0;
}
