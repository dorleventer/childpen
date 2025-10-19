
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
#> Skipping install of 'childpen' from a github remote, the SHA1 (59555853) has not changed since last install.
#>   Use `force = TRUE` to force installation
```

## Example

A basic example of estimating descriptive estimands for several
treatment groups:

``` r
library(childpen)
library(data.table)

set.seed(1)
DT <- CJ(id = 1:60, age = 20:26)
DT[, female := +(id %% 2 == 0)]
DT[, D := rep(sample(24:28, 60, T), each = 7)]
DT[, Y := rnorm(.N, 10 - 0.5*female + 0.1*(age-20))]

# for a single 2-by-2
single_treatment_group_analysis(DT, 24, 25, 24)
#>    estimand     method         est         se n_female_treat n_female_control
#> 1       APO DID_Female 10.71921793 0.56931690              7                7
#> 2       APO   DID_Male 10.12979597 0.51991738              7                7
#> 3       ATE DID_Female -0.62351871 0.58013815              7                7
#> 4       ATE   DID_Male  0.20517057 0.68872104              7                7
#> 5     theta DID_Female -0.05816830 0.05172114              7                7
#> 6     theta   DID_Male  0.02025417 0.06889036              7                7
#> 7       ATE         TD -0.82868928 0.90049816              7                7
#> 8     theta        NTD -0.07842247 0.08614499              7                7
#> 9     theta    NTD_Alt -0.08133820 0.08998474              7                7
#> 10      APO    TD_Null 10.92438850 0.89356500              7                7
#> 11      ATE    TD_Null -0.82868928 0.90049816              7                7
#> 12    theta    TD_Null -0.07585681 0.07680669              7                7
#> 13      APO   NTD_Null 10.93632675 0.93951793              7                7
#> 14      ATE   NTD_Null -0.84062753 0.94474786              7                7
#> 15    theta   NTD_Null -0.07686562 0.08034468              7                7
#>    n_male_treat n_male_control
#> 1             8              6
#> 2             8              6
#> 3             8              6
#> 4             8              6
#> 5             8              6
#> 6             8              6
#> 7             8              6
#> 8             8              6
#> 9             8              6
#> 10            8              6
#> 11            8              6
#> 12            8              6
#> 13            8              6
#> 14            8              6
#> 15            8              6

# over multiple treatment groups
# multiple_treatment_group_analysis(
#   DT,
#   treatment_groups = 24:26,
#   periods_post = 1,
#   periods_pre = 2,
#   pre = 1
# )
```
