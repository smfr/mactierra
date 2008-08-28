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

#include <boost/intrusive/list.hpp>
#include <boost/serialization/serialization.hpp>
#include <boost/serialization/split_member.hpp>

#include "MT_Engine.h"
#include "MT_Cpu.h"
#include "MT_Genotype.h"

typedef boost::intrusive::list_member_hook<> ReaperListHook;
typedef boost::intrusive::list_member_hook<> SlicerListHook;

namespace MacTierra {

class InventoryGenotype;
class Soup;
class World;

class Creature
{
public:
    ReaperListHook  mReaperListHook;
    SlicerListHook  mSlicerListHook;
    
public:
    
    Creature(creature_id inID, Soup* inOwningSoup);
    ~Creature();

    // zero out this creature's space in the soup
    creature_id     creatureID() const  { return mID; }
    
    std::string     creatureName() const;
    
    Soup*           soup() const { return mSoup; }

    u_int32_t       length() const { return mLength; }
    void            setLength(u_int32_t inLength) { mLength = inLength; }

    address_t       location() const { return mLocation; }
    void            setLocation(address_t inLocation) { mLocation = inLocation; }

    bool            containsAddress(address_t inAddress, u_int32_t inSoupSize) const
                    {
                        // This has to take wrapping into account
                        address_t endAddress = (mLocation + mLength) % inSoupSize;
                        return (endAddress > mLocation) ? (inAddress >= mLocation && inAddress < endAddress)
                                                        : (inAddress >= mLocation || inAddress < endAddress);     // wrapping case
                    }
                    
    int32_t         sliceSize() const   { return mSliceSize; }
    void            setSliceSize(int32_t inSize) { mSliceSize = inSize; }

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
    
    // move to soup?
    void            clearSpace();
    
    // execute the mal instruction. can set cpu flag
    void            startDividing(Creature* inDaughter);

    // execute the divide instruction. can set cpu flag
    Creature*       divide(World& inWorld);
    
    bool            isDividing() const          { return mDividing; }
    Creature*       daughterCreature() const    { return mDaughter; }

    void            clearDaughter();
    
    void            noteMoveToOffspring()       { ++mMovesToLastOffspring; }

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
    
    // disallow copy construct and copy
    Creature& operator=(const Creature& inRHS);
    Creature(const Creature& inRHS);

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
    , mSliceSize(0)
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

        ar << BOOST_SERIALIZATION_NVP(mID);
        ar << BOOST_SERIALIZATION_NVP(mGenotype);
        ar << BOOST_SERIALIZATION_NVP(mGenotypeDivergence);
        ar << BOOST_SERIALIZATION_NVP(mCPU);
        ar << BOOST_SERIALIZATION_NVP(mSoup);

        ar << BOOST_SERIALIZATION_NVP(mDaughter);
        bool dividing = mDividing;
        ar << BOOST_SERIALIZATION_NVP(dividing);
        bool born = mBorn;
        ar << BOOST_SERIALIZATION_NVP(born);

        ar << BOOST_SERIALIZATION_NVP(mLength);
        ar << BOOST_SERIALIZATION_NVP(mLocation);
        ar << BOOST_SERIALIZATION_NVP(mSliceSize);
        ar << BOOST_SERIALIZATION_NVP(mLastInstruction);

        ar << BOOST_SERIALIZATION_NVP(mInstructionsToLastOffspring);
        ar << BOOST_SERIALIZATION_NVP(mTotalInstructionsExecuted);
        ar << BOOST_SERIALIZATION_NVP(mBirthInstructions);

        ar << BOOST_SERIALIZATION_NVP(mNumErrors);
        ar << BOOST_SERIALIZATION_NVP(mMovesToLastOffspring);

        ar << BOOST_SERIALIZATION_NVP(mNumOffspring);
        ar << BOOST_SERIALIZATION_NVP(mNumIdenticalOffspring);

        ar << BOOST_SERIALIZATION_NVP(mGeneration);
    }

    template<class Archive> void load(Archive& ar, const unsigned int version)
    {
        // mReaperListHook and mSlicerListHook are filled in when the slicer and reaper lists load

        ar >> BOOST_SERIALIZATION_NVP(mID);
        ar >> BOOST_SERIALIZATION_NVP(mGenotype);
        ar >> BOOST_SERIALIZATION_NVP(mGenotypeDivergence);
        ar >> BOOST_SERIALIZATION_NVP(mCPU);
        ar >> BOOST_SERIALIZATION_NVP(mSoup);

        ar >> BOOST_SERIALIZATION_NVP(mDaughter);
        bool dividing;
        ar >> BOOST_SERIALIZATION_NVP(dividing); mDividing = dividing;
        bool born;
        ar >> BOOST_SERIALIZATION_NVP(born); mBorn = born;

        ar >> BOOST_SERIALIZATION_NVP(mLength);
        ar >> BOOST_SERIALIZATION_NVP(mLocation);
        ar >> BOOST_SERIALIZATION_NVP(mSliceSize);
        ar >> BOOST_SERIALIZATION_NVP(mLastInstruction);

        ar >> BOOST_SERIALIZATION_NVP(mInstructionsToLastOffspring);
        ar >> BOOST_SERIALIZATION_NVP(mTotalInstructionsExecuted);
        ar >> BOOST_SERIALIZATION_NVP(mBirthInstructions);

        ar >> BOOST_SERIALIZATION_NVP(mNumErrors);
        ar >> BOOST_SERIALIZATION_NVP(mMovesToLastOffspring);

        ar >> BOOST_SERIALIZATION_NVP(mNumOffspring);
        ar >> BOOST_SERIALIZATION_NVP(mNumIdenticalOffspring);

        ar >> BOOST_SERIALIZATION_NVP(mGeneration);
    }

    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ::boost::serialization::split_member(ar, *this, file_version);
    }

protected:

    creature_id     mID;
    
    InventoryGenotype*  mGenotype;
    u_int32_t           mGenotypeDivergence;        // number of primes after the name

    Cpu             mCPU;
    
    Soup*           mSoup;
    
    Creature*       mDaughter;

    bool            mDividing : 1;
    bool            mBorn : 1;              // false until parent divides
    
    u_int32_t       mLength;
    address_t       mLocation;          // position in soup
    
    u_int32_t       mSliceSize;         // should this be here?
    instruction_t   mLastInstruction;   // ditto
    
    u_int32_t       mInstructionsToLastOffspring;
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
