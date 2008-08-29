/*
 *  MT_Settings.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/24/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_Settings_h
#define MT_Settings_h

#include <boost/serialization/serialization.hpp>

#include "MT_Engine.h"

namespace MacTierra {

class Settings
{
public:

    static Settings zeroMutationSettings()
    {
        Settings theSettings;
        return theSettings;
    }

    static Settings mediumMutationSettings(u_int32_t inSoupSize)
    {
        Settings theSettings;
        
        theSettings.setFlawRate(8.34E-4);
        theSettings.setCosmicRate(7.634E-9, inSoupSize);
        theSettings.setCopyErrorRate(1.0E-3);
        theSettings.setSliceSizeVariance(2);
        theSettings.setSizeSelection(0.9);
        
        return theSettings;
    }
    
    Settings();
    
    // update computed settings values that depend on soup size
    void            updateWithSoupSize(u_int32_t inSoupSize);

    enum ETimeSliceType {
        kConstantSlizeSize,
        kSizeVariableSliceSize,
    };

    ETimeSliceType  timeSliceType() const    { return mTimeSliceType; }
    void            setTimeSliceType(ETimeSliceType inType) { mTimeSliceType = inType; }
    
    double          constantSliceSize() const       { return mConstantSliceSize; }
    void            setConstantSliceSize(double inSize) { mConstantSliceSize = inSize; }

    double          sliceSizeVariance() const       { return mSliceSizeVariance; }
    void            setSliceSizeVariance(double inVariance) { mSliceSizeVariance = inVariance; }

    double          sizeSelection() const           { return mSizeSelection; }
    void            setSizeSelection(double inSel)  { mSizeSelection = inSel; }

    double          reapThreshold() const { return mReapThreshold; }
    void            setReapThreshold(double inThreshold) { mReapThreshold = inThreshold; }

    double          flawRate() const                { return mFlawRate; }
    void            setFlawRate(double inRate);
    double          meanFlawInterval() const        { return mMeanFlawInterval; }

    double          cosmicRate() const              { return mCosmicRate; }
    void            setCosmicRate(double inRate, u_int32_t inSoupSize);
    double          meanCosmicTimeInterval() const { return mMeanCosmicTimeInterval; }

    double          copyErrorRate() const           { return mCopyErrorRate; }
    void            setCopyErrorRate(double inRate);
    double          meanCopyErrorInterval() const  { return mMeanCopyErrorInterval; }

    enum EMutationType {
        kAddOrDec,
        kBitFlip,
        kRandomChoice
    };

    EMutationType   mutationType() const    { return mMutationType; }
    void            setMutationType(EMutationType inMutationType);

    enum EDaughterAllocationStrategy {
        kRandomAlloc,
        kRandomPackedAlloc,
        kClosestAlloc,
        kPreferredAlloc
    };

    EDaughterAllocationStrategy daughterAllocationStrategy() const;
    void            setDaughterAllocationStrategy(EDaughterAllocationStrategy inStrategy);
    
    bool            globalWritesAllowed() const;
    void            setGlobalWritesAllowed(bool inAllowed);

    bool            transferRegistersToOffspring() const;
    void            setTransferRegistersToOffspring(bool inTransfer);
    
    bool            clearDaughterCells() const    { return mClearDaughterCells; }
    void            setClearDaughterCells(bool inClear) { mClearDaughterCells = inClear; }

    bool            clearReapedCreatures() const    { return mClearReapedCreatures; }
    void            setClearReapedCreatures(bool inClear) { mClearReapedCreatures = inClear; }
    
private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & BOOST_SERIALIZATION_NVP(mTimeSliceType);
        ar & BOOST_SERIALIZATION_NVP(mConstantSliceSize);

        ar & BOOST_SERIALIZATION_NVP(mSliceSizeVariance);

        ar & BOOST_SERIALIZATION_NVP(mCopyErrorRate);
        ar & BOOST_SERIALIZATION_NVP(mMeanCopyErrorInterval);

        ar & BOOST_SERIALIZATION_NVP(mFlawRate);
        ar & BOOST_SERIALIZATION_NVP(mMeanFlawInterval);

        ar & BOOST_SERIALIZATION_NVP(mCosmicRate);
        ar & BOOST_SERIALIZATION_NVP(mMeanCosmicTimeInterval);

        ar & BOOST_SERIALIZATION_NVP(mSizeSelection);
        ar & BOOST_SERIALIZATION_NVP(mLeannessSelection);
        ar & BOOST_SERIALIZATION_NVP(mReapThreshold);

        ar & BOOST_SERIALIZATION_NVP(mLeannessSelection);

        ar & BOOST_SERIALIZATION_NVP(mMutationType);
        ar & BOOST_SERIALIZATION_NVP(mGlobalWritesAllowed);
        ar & BOOST_SERIALIZATION_NVP(mTransferRegistersToOffspring);
        ar & BOOST_SERIALIZATION_NVP(mClearDaughterCells);
        ar & BOOST_SERIALIZATION_NVP(mClearReapedCreatures);

        ar & BOOST_SERIALIZATION_NVP(mDaughterAllocation);
    }

protected:

    ETimeSliceType  mTimeSliceType;

    u_int32_t       mConstantSliceSize;

    double          mSliceSizeVariance;         // sigma of normal distribution

    double          mSizeSelection;             // size selection
    bool            mLeannessSelection;         // select for "lean" creatures
    double          mReapThreshold;             // [0, 1)

    double          mCopyErrorRate;
    double          mMeanCopyErrorInterval;     // computed

    double          mFlawRate;
    double          mMeanFlawInterval;          // computed

    double          mCosmicRate;
    double          mMeanCosmicTimeInterval;    // computed

    EMutationType   mMutationType;
    
    bool            mGlobalWritesAllowed;
    bool            mTransferRegistersToOffspring;
    bool            mClearDaughterCells;
    bool            mClearReapedCreatures;
    
    EDaughterAllocationStrategy mDaughterAllocation;

};


} // namespace MacTierra

#endif // MT_Settings_h
