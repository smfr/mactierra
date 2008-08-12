/**
 * \file RandomType.hpp
 * \brief Class to hold bit-width and unsigned type
 *
 * This provides a simple class to couple a bit-width and an unsigned type
 * capable of holding all the bits.  In addition is offers static methods for
 * I/O and checksumming.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more information, see
 * http://charles.karney.info/random/
 **********************************************************************/
#if !defined(RANDOMTYPE_HPP)
#define RANDOMTYPE_HPP "$Id: RandomType.hpp 6423 2008-01-23 02:11:38Z ckarney $"

#include <limits>
#include <string>
#include <iostream>

namespace RandomLib {
  /**
   * \brief Class to hold bit-width and unsigned type
   *
   * This provides a simple class to couple a bit-width and an unsigned type
   * capable of holding all the bits.  In addition is offers static methods for
   * I/O and checksumming.
   **********************************************************************/
  template<int bits, typename UIntType>
  class RandomType {
  public:
    /**
     * The unsigned C++ type
     **********************************************************************/
    typedef UIntType type;
    /**
     * The number of significant bits
     **********************************************************************/
    static const unsigned width = bits;
    /**
     * A mask for the significant bits.
     **********************************************************************/
    static const type mask =
      ~type(0) >> std::numeric_limits<type>::digits - width;
    /**
     * The minimum representable value
     **********************************************************************/
    static const type min = type(0);
    /**
     * The maximum representable value
     **********************************************************************/
    static const type max = mask;
    /**
     * A combined masking and casting operation
     **********************************************************************/
    template<typename IntType> static type cast(IntType x) throw()
    { return type(x) & mask; }
    /**
     * Read a data value from a stream of 32-bit quantities (binary or text)
     **********************************************************************/
    static void Read32(std::istream& is, bool bin, type& x)
      throw(std::ios::failure);
    /**
     * Read the data value to a stream of 32-bit quantities (binary or text)
     **********************************************************************/
    static void Write32(std::ostream& os, bool bin, int& cnt, type x)
      throw(std::ios::failure);
    /**
     * Accumulate a checksum of a integer into a 32-bit check.  This implements
     * a very simple checksum and is intended to avoid accidental corruption
     * only.
     **********************************************************************/
    static void CheckSum(type n, uint32_t& check) throw();
  };

  /**
   * The standard unit for 32-bit quantities
   **********************************************************************/
  typedef RandomType<32, uint32_t> Random_u32;
  /**
   * The standard unit for 64-bit quantities
   **********************************************************************/
  typedef RandomType<64, uint64_t> Random_u64;

  /// \cond SKIP

  // Accumulate a checksum of a 32-bit quantity into check
  template<>
  inline void Random_u32::CheckSum(Random_u32::type n, Random_u32::type& check)
    throw() {
    // Circular shift left by one bit and add new word.
    check = (check << 1 | check >> 31 & Random_u32::type(1)) + n;
    check &= Random_u32::mask;
  }

  // Accumulate a checksum of a 64-bit quantity into check
  template<>
  inline void Random_u64::CheckSum(Random_u64::type n, Random_u32::type& check)
    throw() {
    Random_u32::CheckSum(Random_u32::cast(n >> 32), check);
    Random_u32::CheckSum(Random_u32::cast(n      ), check);
  }
  /// \endcond

} // namespace RandomLib

#endif	// RANDOMTYPE_HPP
