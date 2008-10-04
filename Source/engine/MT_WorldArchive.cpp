/*
 *  MT_WorldArchive.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 10/3/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_WorldArchive.h"

#include <boost/archive/xml_iarchive.hpp>
#include <boost/archive/xml_oarchive.hpp>

#include <boost/archive/binary_iarchive.hpp>
#include <boost/archive/binary_oarchive.hpp>

#include "MT_World.h"
#include "MT_WorldArchive.h"

namespace MacTierra {

using namespace std;


// static
void
WorldArchive::worldToStream(const World* inWorld, std::ostream& inStream, EWorldSerializationFormat inFormat)
{
    switch (inFormat)
    {
        case kBinary:
            {
                ::boost::archive::binary_oarchive binaryArchive(inStream);
                binaryArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("tierra", inWorld);
            }
            break;

        case kXML:
            {
                ::boost::archive::xml_oarchive xmlArchive(inStream);
                xmlArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("tierra", inWorld);
            }
            break;

        case kAutodetect:
            BOOST_ASSERT(0);
            break;
    }
}

// static
World*
WorldArchive::worldFromStream(std::istream& inStream, EWorldSerializationFormat inFormat)
{
    World* braveNewWorld = NULL;

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
            {
                ::boost::archive::binary_iarchive binaryArchive(inStream);
                binaryArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("tierra", braveNewWorld);
            }
            break;

        case kXML:
            {
                ::boost::archive::xml_iarchive xmlArchive(inStream);
                xmlArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("tierra", braveNewWorld);
            }
            break;

        case kAutodetect:
            BOOST_ASSERT(0);
            break;
    }

    return braveNewWorld;
}


} // namespace MacTierra

