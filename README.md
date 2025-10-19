
<!-- README.md is generated from README.Rmd. Please edit that file -->

# childpen

<!-- badges: start -->

<!-- badges: end -->

The goal of childpen is to provide a helper package for estimating child
penalties using DID, TD and NTD based methods as discussed in Leventer
(2025).

## Installation

You can install the development version of childpen like so:

``` r
# install.packages("remotes")
remotes::install_github("dorleventer/childpen")
#> Using GitHub PAT from the git credential store.
#> Skipping install of 'childpen' from a github remote, the SHA1 (3ac0eb46) has not changed since last install.
#>   Use `force = TRUE` to force installation
```

## Example

A basic example of estimating descriptive estimands for several
treatment groups:

``` r
# library(childpen)
# library(data.table)
# 
# set.seed(1)
# DT <- CJ(id = 1:60, age = 20:26)
# DT[, female := +(id %% 2 == 0)]
# DT[, D := rep(sample(24:28, 60, T), each = 7)]
# DT[, Y := rnorm(.N, 10 - 0.5*female + 0.1*(age-20))]

# for a single 2-by-2
# single_treatment_group_analysis(DT, 24, 25, 24)

# # over multiple treatment groups
# multiple_treatment_group_analysis(
#   DT,
#   treatment_groups = 24:26,
#   periods_post = 1,
#   periods_pre = 2,
#   pre = 1
# )
```
