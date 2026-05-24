## Resubmission

This is a resubmission. The previous submission (0.2.1) was flagged for
excessive CPU time during vignette building (13.7x elapsed time), indicating
use of more than 2 cores. Changes in this version:

* Added `data.table::setDTthreads(1L)` to all vignette setup chunks and test
  setup to restrict data.table's OpenMP threading during CRAN checks.
* Rewrote `simulate_data()` with a self-contained DGP (no internal data
  dependencies). Removed internal datasets and related documentation.
* Rewrote vignettes to focus on estimator usage and interpretation.
  Vignette build time is now ~17 seconds (CPU/elapsed ratio ~1.0).

## R CMD check results

0 errors | 0 warnings | 3 notes

* checking CRAN incoming feasibility ... NOTE: New submission
* checking for future file timestamps ... NOTE: unable to verify current time
* checking HTML version of manual ... NOTE: R's HTML tidy checker flags
  `<main>` tag (standard in all roxygen2-generated HTML on R 4.4.x)

## Possibly misspelled words

* **Leventer** -- author surname (appears in Authors@R and citation)
* **NTD** -- established acronym in the child penalties literature (Normalized Treatment Difference)

## Test environments

* local macOS Sonoma 14.3 (aarch64-apple-darwin20), R 4.4.1
* GitHub Actions: macOS-latest (release), ubuntu-latest (release)

## Downstream dependencies

There are currently no downstream dependencies for this package.
