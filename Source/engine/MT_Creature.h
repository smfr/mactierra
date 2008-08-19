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

#include "MT_Engine.h"
#include "MT_Cpu.h"

namespace MacTierra {

class Soup;
class World;

typedef boost::intrusive::list_member_hook<> ReaperListHook;
typedef boost::intrusive::list_member_hook<> SlicerListHook;

class Creature
{
public:
    ReaperListHook  mReaperListHook;
    SlicerListHook  mSlicerListHook;
    
public:

    typedef std::vector<instruction_t> genome_t;
    
    Creature(creature_id inID, Soup* inOwningSoup);
    ~Creature();

    // zero out this creature's space in the soup
    creature_id     creatureID() const  { return mID; }
    
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
    void            setReferencedLocation(u_int32_t inAddress);

    address_t       addressFromOffset(int32_t inOffset) const;
    int32_t         offsetFromAddress(address_t inAddress) const;
    
    instruction_t   getSoupInstruction(int32_t inOffset) const;
    void            getGenome(genome_t& outGenome) const;

    // this string can have embedded nulls. Not printable.
    std::string     genotypeString() const;
    
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
    
    // called on parent
    void            gaveBirth(Creature* inDaughter);
    void            wasBorn();
    
    bool            isEmbryo() const { return !mBorn; }

    bool            operator==(const Creature& inRHS)
                    {
                        return mID == inRHS.creatureID();
                    }
private:
    
    // disallow copy construct and copy
    Creature& operator=(const Creature& inRHS);
    Creature(const Creature& inRHS);
    
protected:

    creature_id     mID;
    
    Cpu             mCPU;
    
    Soup*           mSoup;
    
    Creature*       mDaughter;
    bool            mDividing;
    
    bool            mBorn;              // false until parent divides
    
    u_int32_t       mLength;
    address_t       mLocation;          // position in soup
    
    u_int32_t       mSliceSize;         // should this be here?
    instruction_t   mLastInstruction;   // ditto
    
    u_int32_t       mInstructionsToLastOffspring;
    u_int64_t       mTotalInstructionsExecuted;
    
    u_int32_t       mNumErrors;
    u_int32_t       mMovesToLastOffspring;

    u_int32_t       mNumOffspring;
    u_int32_t       mNumIdenticalOffspring;
    
    // leanness stuff
    
    
};


} // namespace MacTierra

#endif // MT_Creature_h
