
<!-- README.md is generated from README.Rmd. Please edit that file -->

# childpen <a href="https://dorleventer.github.io/childpen" title="childpen website"><img src="man/figures/logo.png" align="right" height="120" alt="childpen logo" /></a>

<!-- badges: start -->

[![pkgdown](https://github.com/dorleventer/childpen/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/dorleventer/childpen/actions/workflows/pkgdown.yaml)
[![R-CMD-check](https://github.com/dorleventer/childpen/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dorleventer/childpen/actions/workflows/R-CMD-check.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
<!-- badges: end -->

**childpen: Child Penalties Estimators & Simulation Tools**

> This package accompanies my job market paper:  
> **Leventer, Dor (2025).** *Identification of Child Penalties.*  
> [Preprint (coming soon)](#)

- 🧪 DID / TD / NTD estimators (single & multiple treatment groups)
- 🧰 Simulation tools  
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

- [x] **Data simulation** —
  [vignette](https://dorleventer.github.io/childpen/articles/simulation.html)
- [x] **Intuition for NTD bias** —
  [vignette](https://dorleventer.github.io/childpen/articles/NTD-identification.html)
- [x] **DID estimation** —
  [vignette](https://dorleventer.github.io/childpen/articles/DID-estimation.html)
- [x] **TD bias** —
  [vignette](https://dorleventer.github.io/childpen/articles/TD-identification.html)
- [x] **TD / NTD estimation** —
  [vignette](https://dorleventer.github.io/childpen/articles/TD-NTD-estimation.html)
- [x] **Validation tests** —
  [vignette](https://dorleventer.github.io/childpen/articles/validation_tests.html)
- [x] **Aggregate estimates** —
  [vignette](https://dorleventer.github.io/childpen/articles/aggregate-estimands.html)

------------------------------------------------------------------------

## Installation

Install the latest development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("dorleventer/childpen")
#> Using GitHub PAT from the git credential store.
#> Downloading GitHub repo dorleventer/childpen@HEAD
#> 
#> ── R CMD build ─────────────────────────────────────────────────────────────────
#>      checking for file ‘/private/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T/Rtmp6T3gxH/remotes17a9dffa6abc/dorleventer-childpen-d4380b0/DESCRIPTION’ ...  ✔  checking for file ‘/private/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T/Rtmp6T3gxH/remotes17a9dffa6abc/dorleventer-childpen-d4380b0/DESCRIPTION’
#>   ─  preparing ‘childpen’:
#>      checking DESCRIPTION meta-information ...  ✔  checking DESCRIPTION meta-information
#>   ─  checking for LF line-endings in source and make files and shell scripts
#>   ─  checking for empty or unneeded directories
#>   ─  building ‘childpen_0.0.0.9000.tar.gz’
#>      
#> 
#> Warning in i.p(...): installation of package
#> '/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T//Rtmp6T3gxH/file17a9d17564d6/childpen_0.0.0.9000.tar.gz'
#> had non-zero exit status
```
