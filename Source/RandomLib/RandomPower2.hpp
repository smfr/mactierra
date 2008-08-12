/**
 * \file RandomPower2.hpp
 * \brief Header for RandomPower2.
 *
 * Return and multiply by powers of two.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more
 * information, see http://charles.karney.info/random/
 **********************************************************************/

#if !defined(RANDOMPOWER2_HPP)
#define RANDOMPOWER2_HPP "$Id: RandomPower2.hpp 6419 2008-01-16 18:23:01Z ckarney $"

#include <cmath>		// For std::pow

namespace RandomLib {

  /**
   * \brief Return or multiply by powers of 2
   *
   * With some compilers it's fastest to do a table lookup of powers of
   * 2.  If RANDOM_POWERTABLE is 1, a lookup table is used.  If
   * RANDOM_POWERTABLE is 0, then std::pow is used.
   **********************************************************************/
  class RandomPower2 {
  public:
    /**
     * Return powers of 2 (either using a lookup table or std::pow)
     **********************************************************************/
    template<typename RealType> static inline RealType pow2(int n) throw() {
#if RANDOM_POWERTABLE
      return RealType(power2[n - minpow]);
#else
      return std::pow(RealType(2), n);
#endif
    }
    /**
     * Multiply a real by a power of 2
     **********************************************************************/
    template<typename RealType>
    static inline RealType shiftf(RealType x, int n) throw()
    // std::ldexp(x, n); is equivalent, but slower
    { return x * pow2<RealType>(n); }

    // Constants
    enum {
      /**
       * Minimum power in RandomPower2::power2
       **********************************************************************/
#if RANDOM_LONGDOUBLEPREC > 64
      minpow = -120,
#else
      minpow = -64,
#endif
      maxpow = 64		/**< Maximum power in RandomPower2::power2. */
    };
  private:
#if RANDOM_POWERTABLE
    /**
     * Table of powers of two
     **********************************************************************/
    static const float power2[maxpow - minpow + 1]; // Powers of two
#endif
  };

} // namespace RandomLib

#endif	// RANDOMPOWER2_HPP
