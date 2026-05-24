# Changelog

## childpen 0.2.2

- Rewrote
  [`simulate_data()`](https://dorleventer.github.io/childpen/reference/simulate_data.md)
  with a self-contained DGP: lifecycle earnings, gender gap, selection
  on treatment timing, and gendered treatment effects. No internal data
  dependencies.
- Removed internal datasets (`male_profiles`, `female_params`,
  `variance_params`) and related documentation.
- Rewrote vignettes to focus on estimator usage and interpretation
  rather than truth/counterfactual comparisons.
- Fixed CRAN check: restricted `data.table` threads to 1 in all
  vignettes and tests to comply with CRAN’s 2-core policy.
- Added `inst/CITATION` for the underlying paper.

## childpen 0.2.1

- Fixed URL redirects flagged by CRAN incoming checks.
- Replaced `\dontrun{}` with `\donttest{}` in all examples.
- Fixed broken examples in
  [`single_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)
  and
  [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md).

## childpen 0.2.0

- Added
  [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  to aggregate individual estimands into population-level child penalty
  estimates.
- Added vignettes: NTD identification, TD identification, DID
  estimation, estimation, validation tests, aggregation, and notation
  reference.
- Added comprehensive `testthat` test suite (72 tests across all
  exported functions).
- Added GitHub Actions R CMD check CI workflow.
- Renamed NTD estimands for consistency with the identification
  framework in Leventer (2025).
- Fixed
  [`prep_data_table()`](https://dorleventer.github.io/childpen/reference/prep_data_table.md)
  to handle `haven_labelled` columns from survey data imported with
  `haven`.

## childpen 0.1.0

- Initial release with core functions:
  [`simulate_data()`](https://dorleventer.github.io/childpen/reference/simulate_data.md),
  [`single_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md),
  and
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md).
