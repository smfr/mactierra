/*
 *  SerializationTests.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/22/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "SerializationTests.h"

#include <iostream>
#include <fstream>

#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>

#include <boost/archive/xml_iarchive.hpp>
#include <boost/archive/xml_oarchive.hpp>

#include <boost/serialization/serialization.hpp>

#include "MT_Ancestor.h"
#include "MT_Cpu.h"
#include "MT_Creature.h"
#include "MT_Inventory.h"
#include "MT_Reaper.h"
#include "MT_Soup.h"
#include "MT_World.h"

using namespace MacTierra;
using namespace std;

const u_int32_t kSoupSize = 1024;

SerializationTests::SerializationTests()
: mWorld(NULL)
{
}


SerializationTests::~SerializationTests()
{
}

void
SerializationTests::setUp()
{
    mWorld = new World();
    mWorld->initializeSoup(kSoupSize);
}

void
SerializationTests::tearDown()
{
    delete mWorld; mWorld = NULL;
}

void
SerializationTests::runTest()
{
    cout << "SerializationTests" << endl;

    Creature* creature1 = mWorld->insertCreature(100, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
    creature1->setLocation(400);
    creature1->setLength(100);

    // output archive
    {
        std::ofstream textStream("test.out");
        std::ofstream xmlStream("test_out.xml");
        
        ::boost::archive::text_oarchive textArchive(textStream);
        ::boost::archive::xml_oarchive xmlArchive(xmlStream);
        textArchive << BOOST_SERIALIZATION_NVP(mWorld);
        xmlArchive << BOOST_SERIALIZATION_NVP(mWorld);
    }

    // now read it back in
    World* newWorld = NULL;
    {
        std::ifstream textInStream("test.out");
//        std::ifstream xmlInStream("test_out.xml");

        ::boost::archive::text_iarchive textArchive(textInStream);
//        ::boost::archive::text_iarchive xmlArchive(xmlInStream);

        textArchive >> BOOST_SERIALIZATION_NVP(newWorld);
    }

//    TEST_CONDITION(*cloneCreature == *creature1);

    delete newWorld;
}


TestRegistration serializationTestReg(new SerializationTests);
