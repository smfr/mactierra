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

#include <boost/serialization/export.hpp>
#include <boost/serialization/serialization.hpp>
#include <boost/tuple/tuple.hpp>

#include "MT_Inventory.h"

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
    : mCallCount(0)
    , mNextCollectionCount(0)
    , mCollectionInterval(1)
    , mMaxDataCount(ULONG_MAX)
    {
    }

    virtual void collect(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld)
    {
        if (mCallCount == mNextCollectionCount)
        {
            DataLogger::collect(inCollectionType, inInstructionCount, inSlicerCycles, inWorld);
        
            // now see if we should prune
            if (dataCount() > maxDataCount())
                pruneData();
            
            mNextCollectionCount = mCallCount + mCollectionInterval;
        }
        ++mCallCount;
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

    virtual u_int64_t minSlicerCycles() const = 0;
    virtual u_int64_t maxSlicerCycles() const = 0;

    virtual double maxDoubleValue() const = 0;

protected:

    virtual void pruneData() = 0;

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("call_count", mCallCount);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("next_collection_count", mNextCollectionCount);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("collection_interval", mCollectionInterval);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("max_data_count", mMaxDataCount);
    }

protected:

    u_int64_t       mCallCount;
    u_int64_t       mNextCollectionCount;
    u_int32_t       mCollectionInterval;        // based on call count

    u_int32_t       mMaxDataCount;

};

template <class T>
class TypedSimpleDataLogger : public SimpleDataLogger
{
public:
    typedef T data_type;
    typedef boost::tuple<u_int64_t, u_int64_t, data_type> data_tuple;       // instructions, cycles, data
    
    static u_int64_t getInstructions(const data_tuple& data)    { return boost::tuples::get<0>(data); }
    static u_int64_t getSlicerCycles(const data_tuple& data)    { return boost::tuples::get<1>(data); }
    static T getData(const data_tuple& data)                    { return boost::tuples::get<2>(data); }
    
    virtual u_int32_t   dataCount() const { return mData.size(); }

    // engine needs to be locked while using this data
    const std::vector<data_tuple>& data() const { return mData; }
    
    data_type maxValue() const { return mMaxValue; }

    virtual u_int64_t minInstructions() const { return mData.size() > 0 ? getInstructions(mData[0]): 0; }
    virtual u_int64_t maxInstructions() const { return mData.size() > 0 ? getInstructions(mData[mData.size() - 1]) : 0; }

    virtual u_int64_t minSlicerCycles() const { return mData.size() > 0 ? getSlicerCycles(mData[0]): 0; }
    virtual u_int64_t maxSlicerCycles() const { return mData.size() > 0 ? getSlicerCycles(mData[mData.size() - 1]) : 0; }

protected:
    
    virtual void pruneData()
    {
        if (dataCount() > maxDataCount())
        {
            // copy to a new vector rather than removing every other entry,
            // would would be slow
            std::vector<data_tuple> newData;
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
            const data_tuple& curData = mData[i];
            std::cout << curData.first << "  " << curData.second << std::endl;
        }
    }
*/    

    void appendValue(u_int64_t inInstructionCount, u_int64_t inSlicerCycles, data_type inValue)
    {
        mData.push_back(data_tuple(inInstructionCount, inSlicerCycles, inValue));
        mMaxValue = std::max(inValue, mMaxValue);
    }
    
    virtual void collectorChanged()
    {
        // if (mOwningCollector)
        //    mCollectionInterval = mOwningCollector->collectionInterval();
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

    std::vector<data_tuple> mData;
    data_type               mMaxValue;
};

namespace boost {
namespace serialization {

template<class Archive, class T>
void serialize(Archive & ar, boost::tuple<u_int64_t, u_int64_t, T>& data, const unsigned int version)
{
    ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("inst", data.get<0>());
    ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("cycles", data.get<1>());
    ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("data", data.get<2>());
}

} // namespace serialization
} // namespace boost


typedef TypedSimpleDataLogger<u_int32_t> SimpleUInt32DataLogger;
class PopulationSizeLogger : public SimpleUInt32DataLogger
{
public:

    PopulationSizeLogger()
    {
        mMaxValue = 0;
    }
    
    // collectData is called on the engine thread
    virtual void collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld);

    virtual double maxDoubleValue() const { return static_cast<double>(mMaxValue); }

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
    MeanCreatureSizeLogger()
    {
        mMaxValue = 0;
    }

    // collectData is called on the engine thread
    virtual void collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld);

    virtual double maxDoubleValue() const { return static_cast<double>(mMaxValue); }

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
    MaxFitnessDataLogger()
    {
        mMaxValue = 0;
    }

    // collectData is called on the engine thread
    virtual void collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld);

    virtual double maxDoubleValue() const { return static_cast<double>(mMaxValue); }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(SimpleDoubleDataLogger);
    }
};

typedef TypedSimpleDataLogger<std::pair<u_int32_t, u_int32_t> > SimpleFrequencyPairDataLogger;
class TwoGenotypesFrequencyLogger : public SimpleFrequencyPairDataLogger
{
public:
    TwoGenotypesFrequencyLogger()
    : mFirstGenotype(NULL)
    , mSecondGenotype(NULL)
    {
        mMaxValue = std::pair<u_int32_t, u_int32_t>(0, 0);
    }

    // collectData is called on the engine thread
    virtual void collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld);

    virtual double maxDoubleValue() const { return static_cast<double>(mMaxValue.first); }

    void setFirstGenotype(MacTierra::InventoryGenotype* inGenotype)     { mFirstGenotype = inGenotype; }
    void setSecondGenotype(MacTierra::InventoryGenotype* inGenotype)    { mSecondGenotype = inGenotype; }

    MacTierra::InventoryGenotype* firstGenotype() const     { return mFirstGenotype; }
    MacTierra::InventoryGenotype* secondGenotype() const    { return mSecondGenotype; }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(SimpleFrequencyPairDataLogger);
        
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("first_genotype", mFirstGenotype);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("second_genotype", mSecondGenotype);
    }
    
protected:
    // These probably need to be refcounted, but at present the inventory keeps all genotypes around
    MacTierra::InventoryGenotype*      mFirstGenotype;
    MacTierra::InventoryGenotype*      mSecondGenotype;
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

    virtual void collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld) = 0;

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
    virtual void collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld);

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
    virtual void collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const MacTierra::World* inWorld);

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(HistogramRangePairDataLogger);
    }
};



#endif // MT_DataCollectors_h_
