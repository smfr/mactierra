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

#include <boost/serialization/nvp.hpp>
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

    bool            selectForLeanness() const    { return mSelectForLeanness; }
    void            setSelectForLeanness(bool inSet) { mSelectForLeanness = inSet; }

    void            recomputeMutationIntervals(u_int32_t inSoupSize);
    
private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("time_slice_type", mTimeSliceType);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("constant_slice_size", mConstantSliceSize);

        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("slice_size_variance", mSliceSizeVariance);

        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("copy_error_rate", mCopyErrorRate);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("flaw_rate", mFlawRate);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("cosmic_rate", mCosmicRate);
        // We don't serialize the intervals, since they are recomputed from the rates,
        // but someone needs to call recomputeMutationIntervals() after loading

        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("size_selection", mSizeSelection);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("leanness_selection", mLeannessSelection);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("reap_threshold", mReapThreshold);

        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("mutation_type", mMutationType);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("global_writes_allowed", mGlobalWritesAllowed);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("transfer_register_contents_to_offspring", mTransferRegistersToOffspring);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("clear_daughter_cells", mClearDaughterCells);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("clear_reaped_creatures", mClearReapedCreatures);
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("select_for_leanness", mSelectForLeanness);

        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("daughter_allocation_type", mDaughterAllocation);
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
    bool            mSelectForLeanness;
    
    EDaughterAllocationStrategy mDaughterAllocation;

};


} // namespace MacTierra

#endif // MT_Settings_h
