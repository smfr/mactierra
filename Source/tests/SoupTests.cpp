/*
 *  SoupTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 9/12/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "SoupTests.h"

#include <iostream>

#include "MT_Engine.h"
#include "MT_InstructionSet.h"
#include "MT_Soup.h"

using namespace MacTierra;

SoupTests::SoupTests()
: mSoup(NULL)
{
}

SoupTests::~SoupTests()
{
}

void SoupTests::setUp()
{
}

void SoupTests::tearDown()
{
    delete mSoup;
    mSoup = NULL;
}

void SoupTests::runTest()
{
    std::cout << "SoupTests" << std::endl;

    testPowerOfTwoSoup();
    testNonPowerOfTwoSoup();
}

void SoupTests::testPowerOfTwoSoup()
{
    const u_int32_t soupSize = 1024;
    mSoup = new Soup(soupSize);

    memset(const_cast<instruction_t*>(mSoup->soup()), k_or1, soupSize);
    runTemplateTests(soupSize);

    delete mSoup;
    mSoup = NULL;
}

void SoupTests::testNonPowerOfTwoSoup()
{
    const u_int32_t soupSize = 617;
    mSoup = new Soup(soupSize);

    memset(const_cast<instruction_t*>(mSoup->soup()), k_or1, soupSize);
    runTemplateTests(soupSize);

    delete mSoup;
    mSoup = NULL;
}

void SoupTests::runTemplateTests(u_int32_t soupSize)
{
    const u_int32_t templateLength = 5;
    instruction_t targetTemplate[] = { k_nop_1, k_nop_0, k_nop_1, k_nop_0, k_nop_1 };
    
    // Half way through
    mSoup->injectInstructions(soupSize / 2, targetTemplate, templateLength);

    // Wrapping
    mSoup->injectInstructions(soupSize - 1, targetTemplate, templateLength);

    instruction_t sourceTemplate[] = { k_nop_0, k_nop_1, k_nop_0, k_nop_1, k_nop_0 };
    mSoup->injectInstructions(soupSize / 4, sourceTemplate, templateLength);
    mSoup->injectInstructions(3 * soupSize / 4, sourceTemplate, templateLength);

    MacTierra::address_t templateAddr = soupSize / 4;
    u_int32_t foundLength = 0;
    // Simple forwards.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == soupSize / 2);
    TEST_CONDITION(foundLength == templateLength);

    // Simple backwards.
    templateAddr = 3 * soupSize / 4;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == soupSize / 2);
    TEST_CONDITION(foundLength == templateLength);

    // Backwards, wrapping template.
    templateAddr = soupSize / 4;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == soupSize - 1);
    TEST_CONDITION(foundLength == templateLength);

    // Forwards, wrapping template.
    templateAddr = 3 * soupSize / 4;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == soupSize - 1);
    TEST_CONDITION(foundLength == templateLength);
}

TestRegistration soupTestReg(new SoupTests);

