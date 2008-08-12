/**
 * \file ExactExponential.hpp
 * \brief Header for ExactExponential
 *
 * Sample exactly from an exponential distribution.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more
 * information, see http://charles.karney.info/random/
 **********************************************************************/

#if !defined(EXACTEXPONENTIAL_HPP)
#define EXACTEXPONENTIAL_HPP "$Id: ExactExponential.hpp 6415 2008-01-12 19:12:01Z ckarney $"

#include "RandomLib/RandomNumber.hpp"

namespace RandomLib {
  /**
   * \brief Sample exactly from an exponential distribution.
   *
   * Sample \e x >= 0 from exp(-\e x).  Basic method taken from:\n J. von
   * Neumann,\n Various Techniques used in Connection with Random Digits,\n
   * J. Res. Nat. Bur. Stand., Appl. Math. Ser. 12, 36-38 (1951),\n reprinted
   * in Collected Works, Vol. 5, 768-770 (Pergammon, 1963).\n See also:\n
   * M. Abramowitz and I. A. Stegun,\n Handbook of Mathematical Functions\n
   * (National Bureau of Standards, 1964), Sec. 26.8.6.c.2.\n R. E. Forsythe,\n
   * Von Neumann's Comparison Method for Random Sampling from Normal and Other
   * Distributions,\n Math. Comp. 26, 817-826 (1972).\n Knuth, TAOCP, Vol 2,
   * Sec 3.4.1.C.3.
   *
   * The following code illustrates the basic method given by von Neumann:
   * \code
   * // Return a random number x >= 0 distributed with probability exp(-x).
   * double ExpDist(RandomLib::Random& r) {
   *   for (unsigned k = 0; ; ++k) {
   *     double x = r.Fixed(), p = x; // executed 1/(1-exp(-1)) times on avg.
   *     for (unsigned s = 1; ; s ^= 1) { // Parity of loop count
   *       double q = r.Fixed(); // executed exp(p) times on average
   *       if (q >= p)
   *         if (s)
   *           return double(k) + x;
   *         else
   *           break;
   *       p = q;
   *     }
   *   }
   * }
   * \endcode
   * This returns a result consuming exp(1)/(1 - exp(-1)) = 4.30 random
   * numbers on average.  (Von Neumann incorrectly states that the method takes
   * (1 + exp(1))/(1 - exp(-1)) = 5.88 random numbers on average.)  Because of
   * the finite precision of Random::Fixed(), the code snippet above only
   * approximates exp(-\e x).  Instead, it returns \e x with probability \e
   * h(1 - \e h)<sup><i>x</i>/<i>h</i></sup> for \e x = \e ih, \e h =
   * 2<sup>-53</sup>, and integer \e i >= 0.
   *
   * The above is precisely von Neumann's method.  Abramowitz and Stegun
   * consider a variant: sample uniform variants until the first is less
   * than the sum of the rest.  Forsythe converts the > ranking for the runs to
   * >= which makes the analysis of the discrete case more difficult.  He also
   * drops the "trick" by which the integer part of the deviate is given by the
   * number of rejections when finding the fractional part.
   *
   * Von Neumann says of this method: "The machine has in effect computed a
   * logarithm by performing only discriminations on the relative magnitude of
   * numbers in (0,1).  It is a sad fact of life, however, that under the
   * particular conditions of the Eniac it was slightly quicker to use a
   * truncated power series for log(1-\e T) than to carry out all the
   * discriminations.  In conclusion, I should like to mention that the above
   * method can be modified to yield a distribution satisfying any first-order
   * differential equation."  Forsythe attempts to extend the method along the
   * lines of the previous sentence.  However, he merely ends up with a
   * rejection method where the acceptance probability is exp(\e f(\e x)) and
   * one is left wondering whether von Neumann had a less trivial extension in
   * mind.
   *
   * Here the method is extended to use infinite precision uniform deviates
   * implemented by RandomNumber and returning \e exact results for the
   * exponential distribution.  This is possible because only comparisions are
   * done in the method.  The template parameter \a bits specifies the number
   * of bits in the base used for RandomNumber (i.e., base =
   * 2<sup><i>bits</i></sup>).
   *
   * For example the following samples from an exponential distribution and
   * prints various representations of the result.
   * \code
   * #include "RandomLib/RandomNumber.hpp"
   * #include "RandomLib/ExactExponential.hpp"
   *
   *   RandomLib::Random r;
   *   const int bits = 1;
   *   RandomLib::ExactExponential<bits> edist;
   *   for (size_t i = 0; i < 10; ++i) {
   *     RandomLib::RandomNumber<bits> x = edist(r); // Sample
   *     std::pair<double, double> z = x.Range();
   *     std::cout << x << " = "     // Print in binary with ellipsis
   *               << "(" << z.first << "," << z.second << ")"; // Print range
   *     double v = x.Value<double>(r); // Round exactly to nearest double
   *     std::cout << " = " << v << std::endl;
   *   }
   * \endcode
   * Here's a possible result:
   \verbatim
   0.0111... = (0.4375,0.5) = 0.474126
   10.000... = (2,2.125) = 2.05196
   1.00... = (1,1.25) = 1.05766
   0.010... = (0.25,0.375) = 0.318289
   10.1... = (2.5,3) = 2.8732
   0.0... = (0,0.5) = 0.30753
   0.101... = (0.625,0.75) = 0.697654
   0.00... = (0,0.25) = 0.0969214
   0.0... = (0,0.5) = 0.194053
   0.11... = (0.75,1) = 0.867946
   \endverbatim
  **********************************************************************/
  template<int bits = 1> class ExactExponential {
  public:
    /**
     * Return a random deviate with an exponential distribution, exp(-\e x) for
     * \e x >= 0.  Requires 9.316 bits per invocation for \a bits = 1, 6.03
     * digits for \a bits = 2, 5.06 digits for \a bits = 3, and 4.30 =
     * exp(1)/(1 - exp(-1)) digits for large \a bits.  The frequency of bits in
     * the fractional part of the returned result with \a bits = 1:\n
     \verbatim
     bits freq(%)
      1   47.98
      2   25.50
      3   13.13
      4    6.66
      5    3.36
      6    1.68
      7    0.84
      8    0.42
      9    0.21
     10    0.11
     11    0.05
     12    0.03
     13+   0.03
     \endverbatim
     * The average number of bits in fraction = 2.054.  The frequency table of
     * \a bits > 1 can be generated from the table above.  E.g., with \a bits =
     * 2, the result consists of three digits with frequency 3.36% + 1.68% =
     * 5.04%.  The relative frequency of the results for the fractional part
     * with \a bits = 1 can be shown via a histogram\n <img src="exphist.png"
     * width=580 height=750 alt="exact binary sampling of exponential
     * distribution">\n The base of each rectangle gives the range represented
     * by the corresponding binary number and the area is proportional to its
     * frequency.  A PDF version of this figure <a href="exphist.pdf">here</a>.
     * This allows the figure to be magnified to show the rectangles for all
     * binary numbers up to 9 bits.
     **********************************************************************/
    template<class Random> RandomNumber<bits> operator()(Random& r) const;
  private:
    /**
     * Return true with probability exp(-\a p) for \a p in (0,1).  For p =
     * (0,1), uses 5.89 random bits per invocation for \a bits = 1, 3.81 digits
     * for \a bits = 2, 3.20 digits for \a bits = 3, and 2.72 = exp(1) digits
     * for \a bits large.  (5.89 is in [5.888, 5.889].  This is close to but
     * not equal to (1 + exp(1))/(1 - exp(-1)) = 5.882.)
     **********************************************************************/
    template<class Random> bool
    ExpFraction(Random& r, RandomNumber<bits>& p) const;
  };

  template<int bits> template<class Random> inline RandomNumber<bits>
  ExactExponential<bits>::operator()(Random& r) const {
    // A simple rejection method gives the fraction part.  The number of
    // rejections gives the integer part.
    RandomNumber<bits> x;
    int k = 0;
    while (!ExpFraction(r, x)) { // Executed 1/(1 - exp(-1)) on average
      ++k;
      x.Init();
    }
    x.SetInteger(k);
    return x;
  }

  template<int bits> template<class Random> inline bool
  ExactExponential<bits>::ExpFraction(Random& r, RandomNumber<bits>& p)
    const {
    // Implement the von Neumann algorithm.
    RandomNumber<bits> w;		// w = r.Fixed();
    if (!w.LessThan(r, p))	// if (w < p)
      return true;
    RandomNumber<bits> v;
    while (true) {		// Unroll loop to avoid copying RandomNumber
      v.Init();			// v = r.Fixed();
      if (!v.LessThan(r, w))	// if (v < w)
	return false;
      w.Init();			// w = r.Fixed();
      if (!w.LessThan(r, v))	// if (w < v)
	return true;
    }
  }
} // namespace RandomLib
#endif	// EXACTEXPONENTIAL_HPP
