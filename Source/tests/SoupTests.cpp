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

    // Non-zero'd soup
    memset(const_cast<instruction_t*>(mSoup->soup()), k_or1, soupSize);
    runTemplateTests(soupSize);

    // Zero'd soup
    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runTemplateTests(soupSize);

    // More tests
    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runTemplateAtStartTests(soupSize);

    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runWrappedSearchTests(soupSize);

    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runEndConditionTests(soupSize);
    
    delete mSoup;
    mSoup = NULL;
}

void SoupTests::testNonPowerOfTwoSoup()
{
    const u_int32_t soupSize = 617;
    mSoup = new Soup(soupSize);

    // Non-zero'd soup
    memset(const_cast<instruction_t*>(mSoup->soup()), k_or1, soupSize);
    runTemplateTests(soupSize);

    // Zero'd soup
    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runTemplateTests(soupSize);

    // More tests
    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runTemplateAtStartTests(soupSize);

    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runWrappedSearchTests(soupSize);

    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    runEndConditionTests(soupSize);

    delete mSoup;
    mSoup = NULL;
}

void SoupTests::runTemplateTests(u_int32_t soupSize)
{
    const u_int32_t templateLength = 5;
    instruction_t targetTemplate[] = { k_nop_1, k_nop_0, k_nop_1, k_nop_0, k_nop_1 };

    const address_t firstTargetLocation = soupSize / 2;
    const address_t secondTargetLocation = soupSize - 2;
    
    // Half way through
    mSoup->injectInstructions(firstTargetLocation, targetTemplate, templateLength);

    // Wrapping
    mSoup->injectInstructions(secondTargetLocation, targetTemplate, templateLength);

    instruction_t sourceTemplate[] = { k_nop_0, k_nop_1, k_nop_0, k_nop_1, k_nop_0, k_or1 };
    
    const address_t firstTemplateLocation = soupSize / 5;
    const address_t secondTemplateLocation = 3 * soupSize / 4;

    mSoup->injectInstructions(firstTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template
    mSoup->injectInstructions(secondTemplateLocation, sourceTemplate, templateLength + 1);

    address_t templateAddr = firstTemplateLocation;
    u_int32_t foundLength = 0;
    // Simple forwards.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    // Simple backwards.
    templateAddr = secondTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    // Backwards, wrapping template.
    templateAddr = firstTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == secondTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    // Forwards, wrapping template.
    templateAddr = secondTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == secondTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    // Both ways, forward non-wrapping template closer.
    templateAddr = firstTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBothways, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == secondTargetLocation);
    TEST_CONDITION(foundLength == templateLength);
}

void SoupTests::runTemplateAtStartTests(u_int32_t soupSize)
{
    const u_int32_t templateLength = 3;
    instruction_t targetTemplate[] = { k_nop_1, k_nop_0, k_nop_1 };

    const address_t firstTargetLocation = 0;
    mSoup->injectInstructions(firstTargetLocation, targetTemplate, templateLength);

    instruction_t sourceTemplate[] = { k_nop_0, k_nop_1, k_nop_0, k_or1 };
    
    const address_t firstTemplateLocation = soupSize / 2;
    mSoup->injectInstructions(firstTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template

    address_t templateAddr = firstTemplateLocation;
    u_int32_t foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = firstTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = firstTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBothways, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);
}

void SoupTests::runWrappedSearchTests(u_int32_t soupSize)
{
    const u_int32_t templateLength = 3;
    instruction_t targetTemplate[] = { k_nop_1, k_nop_0, k_nop_1 };

    const address_t firstTargetLocation = soupSize / 2 - 1;
    mSoup->injectInstructions(firstTargetLocation, targetTemplate, templateLength);

    instruction_t sourceTemplate[] = { k_nop_0, k_nop_1, k_nop_0, k_or1 };
    
    const address_t firstTemplateLocation = 3 * soupSize / 4;
    mSoup->injectInstructions(firstTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template

    const address_t secondTemplateLocation = soupSize / 4;
    mSoup->injectInstructions(secondTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template

    address_t templateAddr = firstTemplateLocation;
    u_int32_t foundLength = 0;
    // Wrapped forward search.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = secondTemplateLocation;
    foundLength = 0;
    // Wrapped backwards search.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = firstTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBothways, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);
}

void SoupTests::runEndConditionTests(u_int32_t soupSize)
{
    const u_int32_t templateLength = 3;
    instruction_t targetTemplate[] = { k_nop_1, k_nop_0, k_nop_1 };

    // Template at end
    address_t firstTargetLocation = soupSize - templateLength;
    mSoup->injectInstructions(firstTargetLocation, targetTemplate, templateLength);

    instruction_t sourceTemplate[] = { k_nop_0, k_nop_1, k_nop_0, k_or1 };
    
    const address_t firstTemplateLocation = 3 * soupSize / 4;
    mSoup->injectInstructions(firstTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template

    const address_t secondTemplateLocation = soupSize / 4;
    mSoup->injectInstructions(secondTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template

    address_t templateAddr = firstTemplateLocation;
    u_int32_t foundLength = 0;
    // Wrapped forward search.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = secondTemplateLocation;
    foundLength = 0;
    // Wrapped backwards search.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = firstTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBothways, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    // Template at start
    memset(const_cast<instruction_t*>(mSoup->soup()), 0, soupSize);
    firstTargetLocation = 0;
    mSoup->injectInstructions(firstTargetLocation, targetTemplate, templateLength);

    mSoup->injectInstructions(firstTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template
    mSoup->injectInstructions(secondTemplateLocation, sourceTemplate, templateLength + 1);  // + 1 to terminate the template

    templateAddr = firstTemplateLocation;
    foundLength = 0;
    // Wrapped forward search.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kForwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = secondTemplateLocation;
    foundLength = 0;
    // Wrapped backwards search.
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBackwards, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);

    templateAddr = secondTemplateLocation;
    foundLength = 0;
    TEST_CONDITION(mSoup->seachForTemplate(Soup::kBothways, templateAddr, foundLength));
    TEST_CONDITION(templateAddr == firstTargetLocation);
    TEST_CONDITION(foundLength == templateLength);
}

TestRegistration soupTestReg(new SoupTests);

