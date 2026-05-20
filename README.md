
<!-- README.md is generated from README.Rmd. Please edit that file -->

# childpen <a href="https://dorleventer.github.io/childpen" title="childpen website"><img src="man/figures/logo.png" align="right" height="120" alt="childpen logo" /></a>

<!-- badges: start -->

[![pkgdown](https://github.com/dorleventer/childpen/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/dorleventer/childpen/actions/workflows/pkgdown.yaml)
[![R-CMD-check](https://github.com/dorleventer/childpen/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dorleventer/childpen/actions/workflows/R-CMD-check.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
<!-- badges: end -->

> This package accompanies my job market paper: **Leventer, Dor
> (2025).** *Identification of Child Penalties.*

- 🧪 DID / TD / NTD estimators (single & multiple treatment groups)
- 📄 **Paper:** [arXiv:2602.07486](https://arxiv.org/abs/2602.07486)
- 💻 **GitHub:** <https://github.com/dorleventer/childpen>
- 🌐 **Website:** <https://dorleventer.github.io/childpen>

------------------------------------------------------------------------

## Roadmap

**Package functions**

- [x] **Estimation of single 2×2** — `single_treatment_group_analysis()`
- [x] **Wrapper for multiple 2×2** —
  `multiple_treatment_group_analysis()`
- [x] **Data simulation** — `simulate_data()`
- [x] **Aggregation over multiple groups** — `aggregate_estimands()`

**Explainers**

- [x] **Estimation (DID, TD, NTD)** —
  [vignette](https://dorleventer.github.io/childpen/articles/estimation.html)
- [x] **NTD identification** —
  [vignette](https://dorleventer.github.io/childpen/articles/NTD-identification.html)
- [x] **TD identification** —
  [vignette](https://dorleventer.github.io/childpen/articles/TD-identification.html)
- [x] **Validation tests** —
  [vignette](https://dorleventer.github.io/childpen/articles/validation_tests.html)
- [x] **Aggregate estimands** —
  [vignette](https://dorleventer.github.io/childpen/articles/aggregate-estimands.html)

------------------------------------------------------------------------

## Installation

Install the latest development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("dorleventer/childpen")
```
