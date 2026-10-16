// Task 2 microsimulation, C++ kernel behind a plain R function (microsim_rcpp). It consumes R's own RNG stream
// (unif_rand) in exactly the order of the vectorised R version, so both return bit-identical results: the
// equivalence test for this pair is identical(), not a tolerance.
#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

// [[Rcpp::export]]
List microsim_rcpp(int n, int steps, double a, double b, double c) {
  RNGScope scope;  // syncs with set.seed() called from R
  NumericVector age(n), sex(n), events(n), cost(n);
  for (int i = 0; i < n; ++i) age[i] = 20.0 + std::floor(60.0 * unif_rand());
  for (int i = 0; i < n; ++i) sex[i] = unif_rand() < 0.5 ? 1.0 : 0.0;
  for (int t = 1; t <= steps; ++t) {
    const double disc = std::pow(1.03, t);  // R evaluates 1.03^t with C pow()
    for (int i = 0; i < n; ++i) {
      age[i] += 1.0;
      const double p = R::plogis(a + b * age[i] + c * sex[i], 0.0, 1.0, 1, 0);
      const double ev = unif_rand() < p ? 1.0 : 0.0;
      events[i] += ev;
      cost[i] += (1500.0 * ev + 100.0) / disc;
    }
  }
  return List::create(_["events"] = events, _["cost"] = cost);
}
