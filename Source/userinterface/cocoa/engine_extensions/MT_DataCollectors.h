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

#include <string>

#include <boost/serialization/serialization.hpp>

#include "MT_DataCollection.h"

// Data collection is considered to be "outside" the engine. Clients of the engine
// should subclass DataLogger and register their loggers with the engine via
// world()->dataCollector()->addLogger(). It's up to the client to choose how
// to store the collected data, and whether to save that data in soup files.


// This data logger collects up to maxDataCount, then prunes the data, throwing
// away every other data point, to conserve memory and make the graphing quicker.

class SimpleDataLogger : public MacTierra::DataLogger
{
public:
    SimpleDataLogger()
    : mNextCollectionInstructions(0)
    , mCollectionInterval(1)
    , mMaxDataCount(ULONG_MAX)
    {
    }

    virtual void collect(u_int64_t inInstructionCount, const MacTierra::World* inWorld)
    {
        if (inInstructionCount >= mNextCollectionInstructions)
        {
            DataLogger::collect(inInstructionCount, inWorld);
        
            // now see if we should prune
            if (dataCount() > maxDataCount())
                pruneData();
            
            mNextCollectionInstructions = inInstructionCount + mCollectionInterval;
        }
    }

    virtual u_int32_t   dataCount() const = 0;

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

    virtual u_int64_t minInstructions() const = 0;
    virtual u_int64_t maxInstructions() const = 0;

    virtual double maxDoubleValue() const = 0;

protected:

    virtual void pruneData() = 0;

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("next_collection_instructions", mNextCollectionInstructions);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("collection_interval", mCollectionInterval);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("max_data_count", mMaxDataCount);
    }

protected:

    u_int64_t       mNextCollectionInstructions;
    u_int32_t       mCollectionInterval;

    u_int32_t       mMaxDataCount;

};

template <class T>
class TypedSimpleDataLogger : public SimpleDataLogger
{
public:
    typedef T data_type;
    typedef std::pair<u_int64_t, data_type> data_pair;

    TypedSimpleDataLogger()
    : mMaxValue(0)
    {
    }

    virtual u_int32_t   dataCount() const { return mData.size(); }

    // engine needs to be locked while using this data
    const std::vector<data_pair>& data() const { return mData; }
    
    data_type maxValue() const { return mMaxValue; }

    virtual u_int64_t minInstructions() const { return mData.size() > 0 ? mData[0].first : 0; }
    virtual u_int64_t maxInstructions() const { return mData.size() > 0 ? mData[mData.size() - 1].first : 0; }

    virtual double maxDoubleValue() const { return (double)mMaxValue; }

protected:
    
    virtual void pruneData()
    {
        if (dataCount() > maxDataCount())
        {
            // copy to a new vector rather than removing every other entry,
            // would would be slow
            std::vector<data_pair> newData;
            const size_t dataSize = mData.size();
            newData.reserve(dataSize / 2);

            for (size_t i = 0; i <= dataSize / 2; ++i)
                newData.push_back(mData[2 * i]);
            
            mData = newData;
            // now collect half as often
            mCollectionInterval *= 2;
        }
    }

/*
    void printData()
    {
        std::cout << "Data" << std::endl;
        const size_t dataSize = mData.size();
        for (size_t i = 0; i < dataSize; ++i)
        {
            const data_pair& curData = mData[i];
            std::cout << curData.first << "  " << curData.second << std::endl;
        }
    }
*/    

    void appendValue(u_int64_t inInstructionCount, data_type inValue)
    {
        mData.push_back(data_pair(inInstructionCount, inValue));
        mMaxValue = std::max(inValue, mMaxValue);
    }
    
    virtual void collectorChanged()
    {
        if (mOwningCollector)
            mCollectionInterval = mOwningCollector->collectionInterval();
    }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(SimpleDataLogger);

        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("data", mData);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("max_value", mMaxValue);
    }

protected:

    std::vector<data_pair>  mData;
    data_type               mMaxValue;
};

typedef TypedSimpleDataLogger<u_int32_t> SimpleUInt32DataLogger;
class PopulationSizeLogger : public SimpleUInt32DataLogger
{
public:
    // collectData is called on the engine thread
    virtual void collectData(u_int64_t inInstructionCount, const MacTierra::World* inWorld);

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(SimpleUInt32DataLogger);
    }
};


typedef TypedSimpleDataLogger<double> SimpleDoubleDataLogger;
class MeanCreatureSizeLogger : public SimpleDoubleDataLogger
{
public:
    // collectData is called on the engine thread
    virtual void collectData(u_int64_t inInstructionCount, const MacTierra::World* inWorld);

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(SimpleDoubleDataLogger);
    }
};


class MaxFitnessDataLogger : public SimpleDoubleDataLogger
{
public:
    // collectData is called on the engine thread
    virtual void collectData(u_int64_t inInstructionCount, const MacTierra::World* inWorld);

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(SimpleDoubleDataLogger);
    }
};


// Logging tempalate for histogram data. These loggers replace the data each time.
class HistogramDataLogger : public MacTierra::DataLogger
{
public:

    HistogramDataLogger()
    : mMaxBuckets(50)
    {
    }
    
    virtual ~HistogramDataLogger()
    {
    }

    virtual u_int32_t   dataCount() const = 0;
    virtual u_int32_t   maxFrequency() const = 0;
    void                setMaxBuckets(u_int32_t inMax) { mMaxBuckets = inMax; }

    virtual void collectData(u_int64_t inInstructionCount, const MacTierra::World* inWorld) = 0;

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("max_buckets", mMaxBuckets);
    }

protected:
    u_int32_t   mMaxBuckets;
};


// Logging tempalate for histogram data. These loggers replace the data each time.
template <class T>
class TypedHistogramDataLogger : public HistogramDataLogger
{
public:

    typedef T data_type;
    typedef std::pair<data_type, u_int32_t> data_pair;

    TypedHistogramDataLogger()
    : HistogramDataLogger()
    {
    }
    
    ~TypedHistogramDataLogger()
    {
    }

    // engine needs to be locked while using this data
    const std::vector<data_pair>& data() const { return mData; }
    
    virtual u_int32_t   dataCount() const { return mData.size(); }
    virtual u_int32_t   maxFrequency() const
    {
        u_int32_t maxValue = 0;
        for (size_t i = 0; i < mData.size(); ++i)
            maxValue = std::max(maxValue, mData[i].second);
        return maxValue;
    }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(HistogramDataLogger);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("data", mData);
    }

protected:

    std::vector<data_pair>  mData;
};


class GenotypeFrequencyDataLogger : public TypedHistogramDataLogger<std::string>
{
public:

    // collectData is called on the engine thread
    virtual void collectData(u_int64_t inInstructionCount, const MacTierra::World* inWorld);

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
//        ar & boost::serialization::base_object<TypedHistogramDataLogger<std::string> >(*this);
    }
};

// pair is a bucket range
typedef std::pair<u_int32_t, u_int32_t> range_pair;
typedef TypedHistogramDataLogger<range_pair> HistogramRangePairDataLogger;
class SizeHistogramDataLogger : public HistogramRangePairDataLogger
{
public:

    // collectData is called on the engine thread
    virtual void collectData(u_int64_t inInstructionCount, const MacTierra::World* inWorld);

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(HistogramRangePairDataLogger);
    }
};



#endif // MT_DataCollectors_h_
