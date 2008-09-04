/*
 *  MT_DataCollectors.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/30/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_DataCollectors_h_
#define MT_DataCollectors_h_

#include "MT_DataCollection.h"

namespace MacTierra {

// Data collection is considered to be "outside" the engine. Clients of the engine
// should subclass DataLogger and register their loggers with the engine via
// world()->dataCollector()->addLogger(). It's up to the client to choose how
// to store the collected data, and whether to save that data in soup files.


// This data logger collects up to maxDataCount, then prunes the data, throwing
// away every other datum, to conserve memory and make the graphing quicker.
template <class T>
class SimpleDataLogger : public DataLogger
{
public:
    typedef T data_type;

    SimpleDataLogger()
    : mCollectionInterval(1)
    , mCollectionCount(0)
    , mMaxDataCount(ULONG_MAX)
    , mMaxValue(0)
    {
    }

    virtual void collect(u_int64_t inInstructionCount, const World* inWorld)
    {
        ++mCollectionCount;
        if ((mCollectionCount % mCollectionInterval) == 0)
        {
            DataLogger::collect(inInstructionCount, inWorld);
        
            // now see if we should prune
            if (dataCount() > maxDataCount())
                pruneData();
            
            mCollectionCount = 0;
        }
    }

    // engine needs to be locked while using this data
    const std::vector<data_type>& data() const { return mData; }
    
    u_int32_t   dataCount() const { return mData.size(); }

    void setMaxDataCount(u_int32_t inMax)
    {
        if (inMax != mMaxDataCount)
        {
            mMaxDataCount = inMax;
            if (dataCount() > maxDataCount())
                pruneData();
        }
    }
    u_int32_t   maxDataCount() const    { return mMaxDataCount; }
    
    data_type   maxValue() const        { return mMaxValue; }

protected:
    
    void pruneData()
    {
        if (dataCount() > maxDataCount())
        {
            // copy to a new vector rather than removing every other entry,
            // would would be slow
            std::vector<data_type> newData;
            const size_t dataSize = mData.size();
            newData.reserve(dataSize / 2);

            for (size_t i = 0; i < dataSize / 2; ++i)
                newData.push_back(mData[2 * i]);
                
            mData = newData;
            // now collect half as often
            ++mCollectionInterval;
        }
    }

    void appendValue(data_type inValue)
    {
        mData.push_back(inValue);
        mMaxValue = std::max(inValue, mMaxValue);
    }
    
protected:

    u_int32_t       mCollectionInterval;
    u_int32_t       mCollectionCount;

    u_int32_t       mMaxDataCount;
    std::vector<data_type>  mData;
    data_type               mMaxValue;
};

class PopulationSizeLogger : public SimpleDataLogger<u_int32_t>
{
public:

    // collectData is called on the engine thread
    virtual void collectData(u_int64_t inInstructionCount, const World* inWorld);
};


class MeanCreatureSizeLogger : public SimpleDataLogger<double>
{
public:

    // collectData is called on the engine thread
    virtual void collectData(u_int64_t inInstructionCount, const World* inWorld);
};



} // namespace MacTierra


#endif // MT_DataCollectors_h_
