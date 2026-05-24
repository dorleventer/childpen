# childpen 0.2.2

* Fixed CRAN check: restricted `data.table` threads to 1 in vignettes and
  tests to comply with CRAN's 2-core policy.
* Added `treatment_groups` parameter to `simulate_data()` (default `25:28`)
  to control which treatment groups are generated.
* Reduced vignette runtime by using fewer treatment groups and post-treatment
  periods in examples.

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
