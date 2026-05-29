## Resubmission

This is a resubmission. The previous submission (0.2.2) was flagged for
using `T` instead of `TRUE` in function defaults. Changes in this version:

* Replaced `T` with `TRUE` in `multiple_treatment_group_analysis()` default
  for `verbose` parameter (both R source and Rd file).
* Fixed aggregate standard errors in `aggregate_estimands()` to match the
  paper's Appendix G inference formulas.
* Routed skipped-cell diagnostics in `multiple_treatment_group_analysis()`
  through the `verbose` argument so they no longer print unconditionally to
  the console.
* `simulate_data()` now saves and restores the caller's RNG state instead of
  calling `set.seed()` unconditionally, so it no longer alters the global
  random number stream.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking for future file timestamps ... NOTE: unable to verify current time

## Test environments

* local macOS Sonoma 14.3 (aarch64-apple-darwin20), R 4.4.1
* GitHub Actions: macOS-latest (release), ubuntu-latest (release)

## Downstream dependencies

There are currently no downstream dependencies for this package.
