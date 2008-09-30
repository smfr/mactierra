/*
 *  MT_Creature.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_Creature_h
#define MT_Creature_h

#include <string>
#include <vector>

#include <boost/dynamic_bitset.hpp>
#include <boost/intrusive/list.hpp>
#include <boost/serialization/serialization.hpp>
#include <boost/serialization/split_member.hpp>

#include <wtf/PassRefPtr.h>
#include <wtf/RefPtr.h>
#include <wtf/RefCounted.h>

#include "serialize_dynamic_bitset.h"

#include "MT_Engine.h"
#include "MT_Cpu.h"
#include "MT_Genotype.h"

typedef boost::intrusive::list_member_hook<> ReaperListHook;
typedef boost::intrusive::list_member_hook<> SlicerListHook;

namespace MacTierra {

class InventoryGenotype;
class Soup;
class World;

class Creature : public RefCounted<Creature>
{
public:
    ReaperListHook  mReaperListHook;
    SlicerListHook  mSlicerListHook;
    
public:
    
    static PassRefPtr<Creature> create(creature_id inID, u_int32_t inLength, Soup* inOwningSoup)
    {
        return adoptRef(new Creature(inID, inLength, inOwningSoup));
    }
    
    ~Creature();

    // zero out this creature's space in the soup
    creature_id     creatureID() const  { return mID; }
    
    std::string     creatureName() const;
    
    Soup*           soup() const { return mSoup; }

    u_int32_t       length() const { return mLength; }

    address_t       location() const { return mLocation; }
    void            setLocation(address_t inLocation) { mLocation = inLocation; }

    bool            containsAddress(address_t inAddress, u_int32_t inSoupSize) const
                    {
                        // This has to take wrapping into account
                        address_t endAddress = (mLocation + mLength) % inSoupSize;
                        return (endAddress > mLocation) ? (inAddress >= mLocation && inAddress < endAddress)
                                                        : (inAddress >= mLocation || inAddress < endAddress);     // wrapping case
                    }

    // stored as a double since it's used as the mean of a normal distribution
    double          meanSliceSize() const   { return mMeanSliceSize; }
    void            setMeanSliceSize(double inSize) { mMeanSliceSize = inSize; }

    Cpu&            cpu() { return mCPU; }
    const Cpu&      cpu() const { return mCPU; }

    // location pointed to by the instruction pointer
    address_t       referencedLocation() const;
    // the the IP to point to the referenced location
    void            setReferencedLocation(address_t inAddress);

    address_t       addressFromOffset(int32_t inOffset) const;
    int32_t         offsetFromAddress(address_t inAddress) const;
    
    instruction_t   getSoupInstruction(int32_t inOffset) const;

    InventoryGenotype* genotype() const                             { return mGenotype; }
    void            setGenotype(InventoryGenotype* inGenotype)      { mGenotype = inGenotype; }
    u_int32_t       genotypeDivergence() const                      { return mGenotypeDivergence; }
    void            setGenotypeDivergence(u_int32_t inDivergence)   { mGenotypeDivergence = inDivergence; }

    // this string can have embedded nulls. Not printable.
    GenomeData      genomeData() const;
    
    const GenomeData& birthGenome() const                           { return mBirthGenome; }

    // move to soup?
    void            clearSpace();
    
    // execute the mal instruction. can set cpu flag
    void            startDividing(Creature* inDaughter);

    // execute the divide instruction. can set cpu flag
    PassRefPtr<Creature> divide(World& inWorld);
    
    bool            isDividing() const              { return mDividing; }
    const Creature* daughterCreature() const        { return mDaughter.get(); }

    bool            isDead() const                  { return mDead; }

    void            clearDaughter();
    
    void            noteMoveToOffspring(address_t inTargetAddress);

    // leanness is the proportion of instructions executed to produce the first child. Currently,
    // template instructions are not counted.
    void            setExecutedBit(u_int32_t inBitIndex)     { mExecutedBits[inBitIndex] = 1; }
    void            computeLeanness()           { mLeanness = (double)mExecutedBits.count() / mLength; }

    void            setLeanness(double inVal)   { mLeanness = inVal; }
    double          leanness() const            { return mLeanness; }
    
    void            noteErrors()                { if (mCPU.mFlag) ++mNumErrors; }
    u_int32_t       numErrors() const           { return mNumErrors; }
    // for testing
    void            setNumErrors(int32_t inErrors) { mNumErrors = inErrors; }

    void            executedInstruction(instruction_t inInst)
                    {
                        mLastInstruction = inInst;
                        ++mTotalInstructionsExecuted;
                    }

    instruction_t   lastInstruction() const     { return mLastInstruction; }

    bool            genomeIdenticalToCreature(const Creature& inOther) const;
    
    // called on parent. return true if the daughter is identical
    bool            gaveBirth(Creature* inDaughter);

    void            onBirth(const World& inWorld);
    void            onDeath(const World& inWorld);
    
    u_int32_t       numOffspring() const            { return mNumOffspring; }
    u_int32_t       numIdenticalOffspring() const   { return mNumIdenticalOffspring; }

    u_int64_t       instructionsToLastOffspring() const { return mInstructionsToLastOffspring; }

    u_int32_t       generation() const              { return mGeneration; }
    void            setGeneration(u_int32_t inGen)  { mGeneration = inGen; }

    u_int64_t       originInstructions() const      { return mBirthInstructions; }
    void            setOriginInstructions(u_int64_t inInstCount)  { mBirthInstructions = inInstCount; }
    
    bool            isEmbryo() const { return !mBorn; }

    bool            isInSlicerList() const { return mSlicerListHook.is_linked(); }
    bool            isInReaperList() const { return mReaperListHook.is_linked(); }

    bool            operator==(const Creature& inRHS)
                    {
                        return mID == inRHS.creatureID();
                    }
private:

    Creature(creature_id inID, u_int32_t inLength, Soup* inOwningSoup);

    // default ctor for serialization
    Creature()
    : mID(0)
    , mGenotype(NULL)
    , mGenotypeDivergence(0)
    , mSoup(NULL)
    , mDaughter(NULL)
    , mDividing(false)
    , mBorn(false)
    , mLength(0)
    , mLocation(0)
    , mMeanSliceSize(0.0)
    , mLastInstruction(0)
    , mInstructionsToLastOffspring(0)
    , mTotalInstructionsExecuted(0)
    , mBirthInstructions(0)
    , mNumErrors(0)
    , mMovesToLastOffspring(0)
    , mNumOffspring(0)
    , mNumIdenticalOffspring(0)
    , mGeneration(0)
    {
    }

    friend class ::boost::serialization::access;
    template<class Archive> void save(Archive& ar, const unsigned int version) const
    {
        // mReaperListHook and mSlicerListHook are saved by the slicer and reaper lists

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("id", mID);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("birth_genome", mBirthGenome);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("genotype", mGenotype);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("genotype_divergence", mGenotypeDivergence);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("cpu", mCPU);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("soup", mSoup);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("daughter", mDaughter);
        
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("executed_bits", mExecutedBits);

        bool temp = mDividing;
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("dividing", temp);
        temp = mBorn;
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("born", temp);
        temp = mDead;
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("dead", temp);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("length", mLength);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("location", mLocation);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("mean_slice_size", mMeanSliceSize);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("last_instruction", mLastInstruction);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("insts_to_last_offspring", mInstructionsToLastOffspring);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("total_insts", mTotalInstructionsExecuted);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("birth_time", mBirthInstructions);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("num_errors", mNumErrors);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("moves_to_last_offspring", mMovesToLastOffspring);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("num_offspring", mNumOffspring);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("num_identical_offspring", mNumIdenticalOffspring);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("generation", mGeneration);
    }

    template<class Archive> void load(Archive& ar, const unsigned int version)
    {
        // mReaperListHook and mSlicerListHook are filled in when the slicer and reaper lists load

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("id", mID);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("birth_genome", mBirthGenome);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("genotype", mGenotype);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("genotype_divergence", mGenotypeDivergence);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("cpu", mCPU);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("soup", mSoup);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("daughter", mDaughter);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("executed_bits", mExecutedBits);

        bool temp;
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("dividing", temp); mDividing = temp;
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("born", temp); mBorn = temp;
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("dead", temp); mDead = temp;

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("length", mLength);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("location", mLocation);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("mean_slice_size", mMeanSliceSize);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("last_instruction", mLastInstruction);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("insts_to_last_offspring", mInstructionsToLastOffspring);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("total_insts", mTotalInstructionsExecuted);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("birth_time", mBirthInstructions);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("num_errors", mNumErrors);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("moves_to_last_offspring", mMovesToLastOffspring);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("num_offspring", mNumOffspring);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("num_identical_offspring", mNumIdenticalOffspring);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("generation", mGeneration);
    }

    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ::boost::serialization::split_member(ar, *this, file_version);
    }

protected:

    creature_id     mID;
    
    GenomeData      mBirthGenome;                   // genome at birth

    InventoryGenotype*  mGenotype;
    u_int32_t           mGenotypeDivergence;        // number of primes after the name

    Cpu             mCPU;
    
    Soup*           mSoup;
    
    RefPtr<Creature> mDaughter;

    boost::dynamic_bitset<>   mExecutedBits;

    bool            mDividing : 1;
    bool            mBorn : 1;              // false until parent divides
    bool            mDead : 1;
    
    u_int32_t       mLength;
    address_t       mLocation;          // position in soup
    
    double          mMeanSliceSize;
    double          mLeanness;
    instruction_t   mLastInstruction;
    
    u_int64_t       mInstructionsToLastOffspring;       // num instructions executed up to the birth of the most recent offspring
    u_int64_t       mTotalInstructionsExecuted;
    u_int64_t       mBirthInstructions;     // world instructions at birth
    
    u_int32_t       mNumErrors;
    u_int32_t       mMovesToLastOffspring;

    u_int32_t       mNumOffspring;
    u_int32_t       mNumIdenticalOffspring;
    
    u_int32_t       mGeneration;
    
    // leanness stuff
    
    
};

} // namespace MacTierra

/*
namespace boost {
namespace serialization {

template<class Archive>
inline void save_construct_data(Archive& ar, const MacTierra::Creature* inCreature, const unsigned int file_version)
{
    // save data required to construct instance
    MacTierra::creature_id creatureID = inCreature->creatureID();
    ar << creatureID;
    MacTierra::Soup* theSoup = inCreature->soup();
    ar << theSoup;
}

template<class Archive>
inline void load_construct_data(Archive& ar, MacTierra::Creature* inCreature, const unsigned int file_version)
{
    // retrieve data from archive required to construct new instance
    MacTierra::creature_id creatureID;
    ar >> creatureID;
    MacTierra::Soup* theSoup;
    ar >> theSoup;
    // invoke inplace constructor to initialize instance of my_class
    ::new(inCreature)MacTierra::Creature(creatureID, theSoup);
}

} // namespace serialization
} // namespace boost
*/



#endif // MT_Creature_h
