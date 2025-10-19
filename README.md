
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
#> Downloading GitHub repo dorleventer/childpen@HEAD
#> 
#> ── R CMD build ─────────────────────────────────────────────────────────────────
#>      checking for file ‘/private/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T/RtmpmIoIX3/remotesccc0249833d0/dorleventer-childpen-651088f/DESCRIPTION’ ...  ✔  checking for file ‘/private/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T/RtmpmIoIX3/remotesccc0249833d0/dorleventer-childpen-651088f/DESCRIPTION’
#>   ─  preparing ‘childpen’:
#>      checking DESCRIPTION meta-information ...  ✔  checking DESCRIPTION meta-information
#>      Warning: newline within quoted string at multiple_treatment_group_analysis.Rd:75
#>    Warning: /private/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T/RtmpFl66cM/Rbuildccdc5a4d3cc0/childpen/man/multiple_treatment_group_analysis.Rd:78: unknown macro '\Delta'
#>   ─  checking for LF line-endings in source and make files and shell scripts
#>   ─  checking for empty or unneeded directories
#>   ─  building ‘childpen_0.0.0.9000.tar.gz’
#>      
#> 
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
DT[, Y := stats::rnorm(.N, 10 - 0.5*female + 0.1*(age-20))]

# for a single 2-by-2
single_treatment_group_analysis(DT, 24, 25, 24) |> 
  head()
#>   estimand     method         est         se n_female_treat n_female_control
#> 1      APO DID_Female 10.71921793 0.56931690              7                7
#> 2      APO   DID_Male 10.12979597 0.51991738              7                7
#> 3      ATE DID_Female -0.62351871 0.58013815              7                7
#> 4      ATE   DID_Male  0.20517057 0.68872104              7                7
#> 5    theta DID_Female -0.05816830 0.05172114              7                7
#> 6    theta   DID_Male  0.02025417 0.06889036              7                7
#>   n_male_treat n_male_control
#> 1            8              6
#> 2            8              6
#> 3            8              6
#> 4            8              6
#> 5            8              6
#> 6            8              6

# over multiple treatment groups
multiple_treatment_group_analysis(
  DT,
  treatment_groups = 24:26,
  periods_post = 1,
  periods_pre = 2,
  pre = 1
) |> head()
#> 
#> Running analysis for 3 treatment groups...
#> Post-treatment event times: 0 to 1
#> Pre-treatment event times: -3 to -2 (testing 2 control groups: d+1 to d+2)
#> Total estimations: 15 (3 post + 12 pre)
#> 
#> Progress: 1/15 (6.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 2/15 (13.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 3/15 (20.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 4/15 (26.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 5/15 (33.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#>   Error for d=26, event_time=1: Empty subgroup: age=27, female=1, D=26
#> Progress: 6/15 (40.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 7/15 (46.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 8/15 (53.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 9/15 (60.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 10/15 (66.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 11/15 (73.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> 
#> Completed 11 estimations in 0.0 minutes
#>    d dp  a event_time estimand     method         est         se       ci_l
#> 1 24 25 24          0      APO DID_Female 10.71921793 0.56931690  9.6033568
#> 2 24 25 24          0      APO   DID_Male 10.12979597 0.51991738  9.1107579
#> 3 24 25 24          0      ATE DID_Female -0.62351871 0.58013815 -1.7605895
#> 4 24 25 24          0      ATE   DID_Male  0.20517057 0.68872104 -1.1447227
#> 5 24 25 24          0    theta DID_Female -0.05816830 0.05172114 -0.1595417
#> 6 24 25 24          0    theta   DID_Male  0.02025417 0.06889036 -0.1147709
#>          ci_h          t            p n_female_treat n_female_control
#> 1 11.83507906 18.8282095 4.435038e-79              7                7
#> 2 11.14883404 19.4834724 1.516378e-84              7                7
#> 3  0.51355206 -1.0747763 2.824749e-01              7                7
#> 4  1.55506382  0.2979008 7.657789e-01              7                7
#> 5  0.04320513 -1.1246523 2.607364e-01              7                7
#> 6  0.15527928  0.2940058 7.687535e-01              7                7
#>   n_male_treat n_male_control
#> 1            8              6
#> 2            8              6
#> 3            8              6
#> 4            8              6
#> 5            8              6
#> 6            8              6
```
