/*
 *  TestRunner.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/11/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TestRunner_h
#define TestRunner_h

#include <vector>

class TestCase
{
public:

	TestCase() {}
	virtual ~TestCase() {}

	// optional methods
	virtual void setUp() {}
	virtual void tearDown() {}

	// required method
	virtual void runTest() = 0;

	void reportFailure(std::string message);
	
};

#define TEST_CONDITION(c, m) if (!(c)) reportFailure(m);

class TestRegistrar
{
public:
	typedef std::vector<TestCase*>	TestList;
	
	TestList& testList();

	void addTest(TestCase* inTest);

	static TestRegistrar* testRegistrar();
	static void deleteRegistrar();
	
protected:
	TestRegistrar();
	~TestRegistrar();

	static TestRegistrar*	gRegistrar;

	TestList		mTestList;
};


class TestRegistration
{
public:
	TestRegistration(TestCase* inTest)
	{
		TestRegistrar::testRegistrar()->addTest(inTest);
	}
	
};

#endif // TestRunner_h
