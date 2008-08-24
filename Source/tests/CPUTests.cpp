/*
 *  CPUTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/16/08.
 *  Copyright 2008 __MyCompanyName__.MT_A All rights reserved.
 *
 */

#include <iostream>

#include "CPUTests.h"

#include "MT_Ancestor.h"
#include "MT_Cpu.h"
#include "MT_InstructionSet.h"
#include "MT_Soup.h"
#include "MT_World.h"

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
    
    mWorld->setFlawRate(0.0);
    mWorld->setCosmicRate(0.0);
    mWorld->setCopyErrorRate(0.0);
    mWorld->setSliceSizeVariance(0);
    mWorld->setDaughterAllocationStrategy(World::kPreferredAlloc);
    
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

    Cpu modelCPU;
    
    TEST_CONDITION(modelCPU == creature->cpu());
    
    mWorld->iterate(4); // first 4 nops

    modelCPU.mInstructionPointer += 4;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_zero

    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_or1

    ++modelCPU.mInstructionPointer;
    modelCPU.mRegisters[k_cx] = 1;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(2); // k_sh1, k_sh1

    modelCPU.mInstructionPointer += 2;
    modelCPU.mRegisters[k_cx] = 4;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_mov_cd

    ++modelCPU.mInstructionPointer;
    modelCPU.mRegisters[k_dx] = modelCPU.mRegisters[k_cx];
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_adrb

    modelCPU.mRegisters[k_ax] = 4;
    modelCPU.mRegisters[k_cx] = 4;
    modelCPU.mInstructionPointer += 5;

    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_sub_ac
    ++modelCPU.mInstructionPointer;
    modelCPU.mRegisters[k_ax] = modelCPU.mRegisters[k_ax] - modelCPU.mRegisters[k_cx];

    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_mov_ab
    ++modelCPU.mInstructionPointer;
    modelCPU.mRegisters[k_bx] = modelCPU.mRegisters[k_ax];

    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_adrf

    modelCPU.mRegisters[k_ax] = 79;
    modelCPU.mRegisters[k_cx] = 4;
    modelCPU.mInstructionPointer += 5;

    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_inc_a

    ++modelCPU.mInstructionPointer;
    ++modelCPU.mRegisters[k_ax];
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_sub_ab
    
    ++modelCPU.mInstructionPointer;
    modelCPU.mRegisters[k_cx] = modelCPU.mRegisters[k_ax] - modelCPU.mRegisters[k_bx];

    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(4); // skip 1, 1, 0, 1

    modelCPU.mInstructionPointer += 4;
    TEST_CONDITION(modelCPU == creature->cpu());
    
    mWorld->iterate(1); // k_mal

    ++modelCPU.mInstructionPointer;
    
    Creature* daughter1 = creature->daughterCreature();
    TEST_CONDITION(daughter1 && creature->isDividing());
    TEST_CONDITION(daughter1->location() == 180 && daughter1->length() == 80);

    modelCPU.mRegisters[k_ax] = 80;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_call

    modelCPU.push(33);
    modelCPU.mInstructionPointer = 44;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_push_ax

    modelCPU.push(modelCPU.mRegisters[k_ax]);
    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_push_bx

    modelCPU.push(modelCPU.mRegisters[k_bx]);
    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_push_cx

    modelCPU.push(modelCPU.mRegisters[k_cx]);
    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(4); // nops 1, 0, 1, 0

    modelCPU.mInstructionPointer += 4;
    TEST_CONDITION(modelCPU == creature->cpu());

    for (u_int32_t i = 0; i < 80; ++i)
    {
        mWorld->iterate(1); // k_mov_iab

        ++modelCPU.mInstructionPointer;
        TEST_CONDITION(modelCPU == creature->cpu());

        mWorld->iterate(1); // k_dec_c
        ++modelCPU.mInstructionPointer;
        --modelCPU.mRegisters[k_cx];
        TEST_CONDITION(modelCPU == creature->cpu());

        mWorld->iterate(1); // k_if_cz

        if (modelCPU.mRegisters[k_cx] == 0)
        {
            mWorld->iterate(1); // k_jmp
            
            modelCPU.mInstructionPointer = 71;
            TEST_CONDITION(modelCPU == creature->cpu());

            break;
        }
        else
        {
            ++modelCPU.mInstructionPointer;
        }

        ++modelCPU.mInstructionPointer;
        TEST_CONDITION(modelCPU == creature->cpu());

        mWorld->iterate(4); // nops 0, 1, 0, 0

        modelCPU.mInstructionPointer += 4;
        TEST_CONDITION(modelCPU == creature->cpu());

        mWorld->iterate(1); // k_inc_a
        ++modelCPU.mRegisters[k_ax];
        ++modelCPU.mInstructionPointer;
        TEST_CONDITION(modelCPU == creature->cpu());

        mWorld->iterate(1); // k_inc_b
        ++modelCPU.mRegisters[k_bx];
        ++modelCPU.mInstructionPointer;
        TEST_CONDITION(modelCPU == creature->cpu());

        mWorld->iterate(1); // k_jmp
        modelCPU.mInstructionPointer = 51;
        TEST_CONDITION(modelCPU == creature->cpu());
    }

    mWorld->iterate(1); // k_pop_cx
    modelCPU.mRegisters[k_cx] = modelCPU.pop();
    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_pop_bx
    modelCPU.mRegisters[k_bx] = modelCPU.pop();
    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_pop_ax
    modelCPU.mRegisters[k_ax] = modelCPU.pop();
    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_ret

    modelCPU.mInstructionPointer = modelCPU.pop();
    TEST_CONDITION(modelCPU == creature->cpu());

    mWorld->iterate(1); // k_divide

    ++modelCPU.mInstructionPointer;
    TEST_CONDITION(modelCPU == creature->cpu());

    TEST_CONDITION(!creature->isDividing() && !creature->daughterCreature());

    GenomeData parentGenome = creature->genomeData();
    GenomeData daughterGenome = daughter1->genomeData();
    TEST_CONDITION(parentGenome == daughterGenome);
    
    mWorld->iterate(1); // k_jmp
    modelCPU.mInstructionPointer = 27;
    TEST_CONDITION(modelCPU == creature->cpu());
    
    Creature* daughter2 = NULL;
    
    // now keep running and look for the second daughter
    bool done = false;
    while (!done)
    {
        mWorld->iterate(1);
    
        switch (creature->lastInstruction())
        {
            case k_mal:
                daughter2 = creature->daughterCreature();
                TEST_CONDITION(daughter2 && creature->isDividing());
                TEST_CONDITION(daughter2->location() == 260 && daughter2->length() == 80);
                break;

            case k_divide:
                GenomeData daughter2Genome = daughter2->genomeData();
                TEST_CONDITION(parentGenome == daughter2Genome);

                done = true;
                break;
        }
        
    }
    
    daughter1->clearDaughter();
}

TestRegistration cpuTestReg(new CPUTests);
