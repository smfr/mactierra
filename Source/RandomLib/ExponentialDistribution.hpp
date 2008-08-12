/**
 * \file ExponentialDistribution.hpp
 * \brief Header for ExponentialDistribution
 *
 * Sample from an exponential distribution.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more
 * information, see http://charles.karney.info/random/
 **********************************************************************/

#if !defined(EXPONENTIALDISTRIBUTION_HPP)
#define EXPONENTIALDISTRIBUTION_HPP "$Id: ExponentialDistribution.hpp 6415 2008-01-12 19:12:01Z ckarney $"

#include <cmath>

namespace RandomLib {
  /**
   * \brief The exponential distribution.
   *
   * Sample from the distribution exp(-\e x) for \e x >= 0.  This uses the
   * logarithm method, see Knuth, TAOCP, Vol 2, Sec 3.4.1.D.  Example
   * \code
   *   #include "RandomLib/ExponentialDistribution.hpp"
   *
   *   RandomLib::Random r;
   *   std::cout << "Seed set to " << r.SeedString() << std::endl;
   *   RandomLib::ExponentialDistribution<double> expdist;
   *   std::cout << "Select from exponential distribution:";
   *   for (size_t i = 0; i < 10; ++i)
   *       std::cout << " " << expdist(r);
   *   std::cout << std::endl;
   * \endcode
   **********************************************************************/
  template<typename RealType = double> class ExponentialDistribution {
  public:
    /**
     * The type returned by ExponentialDistribution::operator()(Random&)
     **********************************************************************/
    typedef RealType result_type;
    /**
     * Return a sample of type RealType from the exponential distribution and
     * mean \a mu.  This uses Random::FloatU() which avoids taking log(0) and
     * allows rare large values to be returned.  If \a mu = 1, minimum returned
     * value = 0 with prob 1/2<sup><i>p</i></sup>; maximum returned value =
     * log(2)(\e p + \e e) with prob 1/2<sup><i>p</i> + <i>e</i></sup>.  Here
     * \e p is the precision of real type RealType and \e e is the exponent
     * range.
     **********************************************************************/
    template<class Random>
    RealType operator()(Random& r, RealType mu = RealType(1)) const throw();
  };

  template<typename RealType>  template<class Random> inline RealType
  ExponentialDistribution<RealType>::operator()(Random& r, RealType mu) const
    throw() {
    return -mu * std::log(r.template FloatU<RealType>());
  }
} // namespace RandomLib
#endif // EXPONENTIALDISTRIBUTION_HPP
