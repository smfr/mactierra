/*
 *  MT_SoupConfiguration.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 9/23/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */


#ifndef MT_SoupConfiguration_h_
#define MT_SoupConfiguration_h_

#include "MT_Engine.h"

#include "MT_Settings.h"

namespace MacTierra {

// Used for saving settings independently
class SoupConfiguration
{
public:

    SoupConfiguration(u_int32_t inSoupSize, u_int32_t inRandomSeed, const Settings& inSettings)
    : mSoupSize(inSoupSize)
    , mRandomSeed(inRandomSeed)
    , mSettings(inSettings)
    {
    }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("soup_size", mSoupSize);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("random_seed", mRandomSeed);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("settings", mSettings);
    }

protected:
    
    u_int32_t       mSoupSize;
    u_int32_t       mRandomSeed;

    Settings        mSettings;
    
};


} // namespace MacTierra


#endif // MT_SoupConfiguration_h_
