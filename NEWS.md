# childpen (development version)

* `single_treatment_group_analysis()` gains two proportional triple-differences
  estimators from the paper's online appendix ("Proportional DID and TD"), both
  built on the multiplicative imputation of counterfactual earnings, with
  cluster-robust influence-function standard errors:
  `TD_E_LOGS` (estimand `"Delta_rho"`, the effect of parenthood on the gender
  earnings ratio, as identified under TD-E-LOGS) and `TD_PR` (estimand
  `"theta_pre"`, the gender gap in effects relative to pre-birth earnings, as
  identified under TD-PR). Each triplet now returns 17 rows; existing rows are
  unchanged.
* `multiple_treatment_group_analysis()` carries the two new rows and their
  individual-level influence functions.
* `aggregate_estimands()` aggregates `TD_E_LOGS` (`gender_ineq`) and `TD_PR`
  (`avg_of_ratios`) and includes both in the default `methods`.

# childpen 0.2.3

* Replaced `T` with `TRUE` in `multiple_treatment_group_analysis()` default
  for `verbose` parameter, as flagged by CRAN review.
* Fixed aggregate standard errors in `aggregate_estimands()` to correctly
  implement the paper's Appendix G inference formulas.
* `multiple_treatment_group_analysis()` now routes skipped-cell diagnostics
  (e.g. empty subgroups) through the `verbose` argument; previously these
  printed unconditionally to the console.
* `simulate_data()` now saves and restores the caller's RNG state on exit, so
  it no longer alters the global random stream. Generated output is unchanged.
  `seed = NULL` is now accepted to draw from the current RNG without reseeding.

# childpen 0.2.2

* Rewrote `simulate_data()` with a self-contained DGP: lifecycle earnings,
  gender gap, selection on treatment timing, and gendered treatment effects.
  No internal data dependencies.
* Removed internal datasets (`male_profiles`, `female_params`,
  `variance_params`) and related documentation.
* Rewrote vignettes to focus on estimator usage and interpretation rather
  than truth/counterfactual comparisons.
* Fixed CRAN check: restricted `data.table` threads to 1 in all vignettes
  and tests to comply with CRAN's 2-core policy.
* Added `inst/CITATION` for the underlying paper.

# childpen 0.2.1

* Fixed URL redirects flagged by CRAN incoming checks.
* Replaced `\dontrun{}` with `\donttest{}` in all examples.
* Fixed broken examples in `single_treatment_group_analysis()` and
  `aggregate_estimands()`.

# childpen 0.2.0

* Added `aggregate_estimands()` to aggregate individual estimands into
  population-level child penalty estimates.
* Added vignettes: NTD identification, TD identification, DID estimation,
  estimation, validation tests, aggregation, and notation reference.
* Added comprehensive `testthat` test suite (72 tests across all exported
  functions).
* Added GitHub Actions R CMD check CI workflow.
* Renamed NTD estimands for consistency with the identification framework in
  Leventer (2025).
* Fixed `prep_data_table()` to handle `haven_labelled` columns from survey
  data imported with `haven`.

# childpen 0.1.0

* Initial release with core functions: `simulate_data()`,
  `single_treatment_group_analysis()`, and
  `multiple_treatment_group_analysis()`.
