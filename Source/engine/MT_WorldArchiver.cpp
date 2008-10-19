/*
 *  MT_WorldArchive.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 10/3/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_WorldArchiver.h"

#include <boost/archive/polymorphic_binary_oarchive.hpp>
#include <boost/archive/polymorphic_xml_oarchive.hpp>

#include <boost/archive/polymorphic_binary_iarchive.hpp>
#include <boost/archive/polymorphic_xml_iarchive.hpp>

#include "MT_World.h"
#include "MT_WorldArchiver.h"

namespace MacTierra {

using namespace std;

void
WorldArchiver::registerAddition(const std::vector<std::string>& inTypes, WorldArchivingAddition* inAddition)
{
    std::vector<std::string>::const_iterator end = inTypes.end();
    for (std::vector<std::string>::const_iterator it = inTypes.begin(); it != end; ++it)
        mAdditions[*it] = inAddition;
}

std::vector<std::string>
WorldArchiver::additionTypes() const
{
    vector<string> typesList;
    
    AdditionsMap::const_iterator end = mAdditions.end();
    for (AdditionsMap::const_iterator it = mAdditions.begin(); it != end; ++it)
        typesList.push_back(it->first);
    
    return typesList;
}

#pragma mark -

WorldExporter::WorldExporter(std::ostream& inStream, EWorldSerializationFormat inFormat)
: mArchive(NULL)
{
    createArchive(inStream, inFormat);
}

WorldExporter::~WorldExporter()
{
    delete mArchive;
}

void
WorldExporter::saveWorld(const World* inWorld)
{
    saveToArchive(inWorld);
}

void
WorldExporter::createArchive(std::ostream& inStream, EWorldSerializationFormat inFormat)
{
    switch (inFormat)
    {
        case kBinary:
            mArchive = new boost::archive::polymorphic_binary_oarchive(inStream);
            break;

        case kXML:
            mArchive = new boost::archive::polymorphic_xml_oarchive(inStream);
            break;

        default:
            break;
    }
    BOOST_ASSERT(mArchive != NULL);
}

void
WorldExporter::saveToArchive(const World* inWorld)
{
    *mArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("tierra", inWorld);
    
    // save list of additions
    std::vector<std::string> additions = additionTypes();
    *mArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("additions", additions);

    // save each addition
    AdditionsMap::const_iterator end = mAdditions.end();
    for (AdditionsMap::const_iterator it = mAdditions.begin(); it != end; ++it)
    {
        WorldArchivingAddition* curAddition = it->second.get();
        curAddition->registerTypes(*mArchive);
        curAddition->saveAddition(it->first, *mArchive);
    }
}

#pragma mark -


WorldImporter::WorldImporter(std::istream& inStream, EWorldSerializationFormat inFormat)
: mArchive(NULL)
{
    createArchive(inStream, inFormat);
}

WorldImporter::~WorldImporter()
{
    delete mArchive;
}

World*
WorldImporter::loadWorld()
{
    return loadFromArchive();
}

void
WorldImporter::createArchive(std::istream& inStream, EWorldSerializationFormat inFormat)
{
    if (inFormat == kAutodetect)
    {
        inStream.seekg(0);

        string header;
        inStream >> header;
        
        if (header.compare("<?xml") == 0)
            inFormat = kXML;
        else
            inFormat = kBinary;
        
        inStream.seekg(0);
    }
    
    switch (inFormat)
    {
        case kBinary:
            mArchive = new boost::archive::polymorphic_binary_iarchive(inStream);
            break;

        case kXML:
            mArchive = new boost::archive::polymorphic_xml_iarchive(inStream);
            break;
        
        default:
            break;
    }

    BOOST_ASSERT(mArchive != NULL);
}

World*
WorldImporter::loadFromArchive()
{
    World* newWorld = NULL;
    *mArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("tierra", newWorld);
    
    // load the list of additions
    std::vector<std::string> additions;
    *mArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("additions", additions);
    
    // load each matching addition
    std::vector<std::string>::const_iterator end = additions.end();
    for (std::vector<std::string>::const_iterator it = additions.begin(); it != end; ++it)
    {
        const std::string& additionType = *it;
        AdditionsMap::const_iterator findIt = mAdditions.find(additionType);
        if (findIt != mAdditions.end())
        {
            WorldArchivingAddition* curAddition = findIt->second.get();
            curAddition->registerTypes(*mArchive);
            curAddition->loadAddition(additionType, *mArchive);
        }
    }
    
    return newWorld;
}


} // namespace MacTierra
