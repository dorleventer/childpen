# Changelog

## childpen 0.3.0

Labels, arguments and help pages now follow the paper. This release
changes the output format; there are no deprecated aliases. All
estimates and standard errors of rows that exist in both versions are
unchanged (checked with `dev/snapshot_compare.R` against v0.2.3 output).

### Breaking changes

- Method and estimand labels: `NTD_Conv` / `theta` is now `Conventional`
  / `gap_theta`; `NTD_New` / `Delta_rho` is now `NTD` / `rho_effect`;
  `TD` / `ATE` is now `TD` / `gap_ATE`; `TD_E_LOGS` / `Delta_rho` is now
  `TD_E_LOGS` / `rho_effect`; `TD_PR` / `theta_pre` is now `TD_PR` /
  `gap_theta_pre`.
- The fathers’-null rows `TD_Null` and `NTD_Conv_Null` are removed; see
  [`bias_bounds()`](https://dorleventer.github.io/childpen/reference/bias_bounds.md).
- [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md):
  `max_age` is now `max_control_group` (it bounds the control group d’,
  the paper’s D_max) and `min_age` is now `min_pre_age` (it bounds the
  target age of pre-treatment cells). `periods_post` must be one number
  H (event times 0..H); `periods_pre = 0` now means no pre-treatment
  cells (it used to run e = -1 and -2).
- [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md):
  `agg_type` is `"weighted_avg"` (was `"avg_of_ratios"` and
  `"gender_ineq"`) or `"ratio_of_avgs"`.

### New

- [`bias_bounds()`](https://dorleventer.github.io/childpen/reference/bias_bounds.md):
  the paper’s bias-bounding exercise (Proposition 2), the bias-corrected
  conventional gap at assumed fathers’ effects (default
  `theta_m = c(-0.1, 0.1)`) for every post-treatment cell, with
  influence-function standard errors.
- Accounting rows for `NTD` and `TD_E_LOGS`: `rho_obs`, `rho_cf`,
  `share_parenthood` (parenthood’s share of the gender gap) and
  `share_other`, with standard errors; also aggregated by
  [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md).
- [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  aggregates the `TD` gap (`gap_ATE`), accepts `weights = "uniform"`,
  and reports `t` and `p`.
- [`single_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)
  returns the same columns as
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  (`d`, `dp`, `a`, `event_time`, `control_offset`, `ci_l`, `ci_h`, `t`,
  `p`); results carry `control_offset` (= dp - d), and
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  attaches `attr(, "skipped")`.
- Articles follow the paper, in order: Notation and output, Estimation
  (every estimator, its influence function, and the assumption behind
  each row), Aggregation, and Replicating the paper (the paper’s main
  figures, including the accounting exercise, on simulated data; on the
  site only).

### Input checks and messages

- Gender labels outside a recognised set (“1”/“0”, “female”/“male”,
  “f”/“m”, …) are an error; before, text codes such as “1”/“2” silently
  swapped genders.
- Rows with missing earnings are dropped with a message (before, one
  missing value made every estimate `NA`); a missing or infinite age at
  first birth marks a person who never has a child.
- Duplicate (id, age) rows, gender or age at first birth varying within
  a person, and missing ids are errors; messages name the argument to
  fix.
- A data.table input is no longer modified in place, and the column-name
  arguments now work for data.table input in
  [`single_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md).
- Invalid comparisons are errors: a control group already treated at the
  target age (`dp <= a`), `dp <= d`, `pre < 1`, or a target age equal to
  the baseline.
- Progress is reported with
  [`message()`](https://rdrr.io/r/base/message.html), one line per
  treatment group; cells that cannot be estimated are summarised in one
  message.
- [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  stops when `results` lacks the influence functions (it used to fall
  back to standard errors that treat treatment groups as independent).
- [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  stops when no weight name matches a treatment group and warns about
  groups without a weight; `n_groups` counts groups with positive
  weight.
- [`simulate_data()`](https://dorleventer.github.io/childpen/reference/simulate_data.md)
  has a new design that shows the paper’s patterns: career entry later
  and growth steeper for later first births (parallel trends fails in
  the paper’s direction; pre-treatment DID estimates grow in magnitude
  with the distance to the control group), effects of parenthood that
  differ by age at first birth and fade with event time, and a gender
  earnings ratio that falls with age (so NTD holds approximately,
  TD-E-LOGS exactly). The true values for every treatment group and age
  are attached (`attr(, "truth")`). The simulated data differ from
  earlier versions. It also works with a single treatment group and
  checks its inputs.
- [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  stops when no cell can be estimated, and
  [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  stops when no requested method is in `results` or nothing can be
  aggregated (both used to return an empty data.frame).
- A non-numeric outcome column is an error (it used to be coerced).
- Row order:
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  sorts by `d`, `event_time`, `dp`;
  [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  by `method`, `agg_type`, `event_time`.

### Speed and memory

- Each 2x2 comparison now uses only the rows of its two groups at the
  baseline and target ages, and stores influence functions only for the
  persons in them; the influence functions and variances are still
  scaled by the full data’s number of rows and persons. In a 280,000-row
  test,
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  runs about 6 times faster (191 s to 33 s) and the stored influence
  functions take about 5 times less memory (418 MB to 76 MB). Results
  are unchanged up to floating-point rounding (`dev/perf_check.R`).

### Bug fixes (standard errors change)

- [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  with `weights = "sample"` (the default): the term for the estimated
  treatment-group shares in the influence function (the paper’s
  estimation and inference appendix) divided by the number of persons in
  the aggregated groups instead of their share, so it was about n times
  too small and the standard errors treated the weights as known. It now
  follows the paper’s formula. Point estimates are unchanged; standard
  errors are larger when treatment-group estimates differ (in a test
  design with heterogeneous effects, the old standard error was 22%
  below a person bootstrap, the new one matches it). `ratio_of_avgs` now
  also includes the share term. Standard errors with uniform or fixed
  weights are unchanged.
- `aggregate_estimands(include_pre = TRUE)` failed (or pooled control
  groups as if they were treatment groups). Pre-treatment cells are now
  aggregated separately for each control offset, reported in the new
  `control_offset` column.

### Proportional triple differences

- Two estimators from the paper’s online appendix “Proportional DID and
  TD”, built on the multiplicative imputation of counterfactual
  earnings, with cluster-robust influence-function standard errors:
  `TD_E_LOGS` (estimand `rho_effect`, the effect of parenthood on the
  gender earnings ratio, as identified under TD-E-LOGS) and `TD_PR`
  (estimand `gap_theta_pre`, the gender gap in effects relative to
  pre-birth earnings, as identified under TD-PR). Both are carried by
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  and aggregated by
  [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md);
  their standard errors are validated by Monte Carlo
  (`dev/sims/td_sim_results.md` in the source repository).

## childpen 0.2.3

CRAN release: 2026-06-02

- Replaced `T` with `TRUE` in
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  default for `verbose` parameter, as flagged by CRAN review.
- Fixed aggregate standard errors in
  [`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
  to correctly implement the paper’s Appendix G inference formulas.
- [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  now routes skipped-cell diagnostics (e.g. empty subgroups) through the
  `verbose` argument; previously these printed unconditionally to the
  console.
- [`simulate_data()`](https://dorleventer.github.io/childpen/reference/simulate_data.md)
  now saves and restores the caller’s RNG state on exit, so it no longer
  alters the global random stream. Generated output is unchanged.
  `seed = NULL` is now accepted to draw from the current RNG without
  reseeding.

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
