
<!-- README.md is generated from README.Rmd. Please edit that file -->

# childpen <a href="https://dorleventer.github.io/childpen" title="childpen website"><img src="man/figures/logo.png" align="right" height="120" alt="childpen logo" /></a>

<!-- badges: start -->

[![pkgdown](https://github.com/dorleventer/childpen/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/dorleventer/childpen/actions/workflows/pkgdown.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
<!-- badges: end -->

**Identification of Child Penalties: Estimators & Simulation Tools**

> **Leventer, Dor (2025).** *Identification of Child Penalties.*  
> Tel Aviv University, Job Market Paper.  
> [Preprint (coming soon)](#) · [Slides (coming soon)](#)

- 📦 **R package:** childpen  
- 🧪 DID / TD / NTD estimators (single & multiple treatment groups)  
- 🧰 Simulation tools and influence-function SEs  
- 💻 **GitHub:** <https://github.com/dorleventer/childpen>  
- 🌐 **Website:** <https://dorleventer.github.io/childpen> *(auto-built
  with pkgdown)*

------------------------------------------------------------------------

## Installation

Install the latest development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("dorleventer/childpen")
#> Using GitHub PAT from the git credential store.
#> Skipping install of 'childpen' from a github remote, the SHA1 (f4d8eca8) has not changed since last install.
#>   Use `force = TRUE` to force installation
```

## Simulating data

The function *simulate_data()* creates a panel of synthetic individuals,
with gender, treatment group (D), and earnings paths that are motivated
by the child penalty application. It uses default DGP parameters bundled
with the package that are based on observable earnings data in Israel.
More data on the simulation can be found in the vignette.

``` r
library(childpen)

sim_data <- simulate_data(n_individuals = 1000, seed = 42)
head(sim_data)
#>   id female age  D     Y_inf         Y
#> 1  1      1  20 30  66775.08  66775.08
#> 2  1      1  21 30  18105.66  18105.66
#> 3  1      1  22 30  21744.97  21744.97
#> 4  1      1  23 30  71501.84  71501.84
#> 5  1      1  24 30 132133.43 132133.43
#> 6  1      1  25 30 194425.57 194425.57
```

## Analyzing single 2-by-2s

The work behind the scenes is done by the function below, which
estimates all relevant parameters for a single 2-by-2 comparison.

``` r
single_treatment_group_analysis(sim_data, d = 25, dp = 26, a = 25, pre = 1) |> head()
#>   estimand     method           est           se n_female_treat
#> 1      APO DID_Female  5.856580e+04 1.148401e+04             40
#> 2      APO   DID_Male  6.598934e+04 1.025988e+04             40
#> 3      ATE DID_Female -1.820565e+04 1.146700e+04             40
#> 4      ATE   DID_Male  3.940978e+03 1.125230e+04             40
#> 5    theta DID_Female -3.108580e-01 1.409049e-01             40
#> 6    theta   DID_Male  5.972143e-02 1.753715e-01             40
#>   n_female_control n_male_treat n_male_control
#> 1               23           32             32
#> 2               23           32             32
#> 3               23           32             32
#> 4               23           32             32
#> 5               23           32             32
#> 6               23           32             32
```

## Analyzing multiple treatment groups

The main function of the package provides estimates over a vector of
treatment groups, up to *periods_post* post treatment. Pre-treatment
periods used in validation test are set using *periods_pre*. The
anticipation period can be set by the researcher using *pre*, default is
one period before treatment.

``` r
res_multi <- multiple_treatment_group_analysis(
  data = sim_data,
  treatment_groups = 25,
  periods_post = 5,
  periods_pre = 4,
  pre = 1
)
#> 
#> Running analysis for 1 treatment groups...
#> Post-treatment event times: 0 to 5
#> Pre-treatment event times: -5 to -2 (testing 6 control groups: d+1 to d+6)
#> Total estimations: 30 (6 post + 24 pre)
#> 
#> Progress: 1/30 (3.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 2/30 (6.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 3/30 (10.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 4/30 (13.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 5/30 (16.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 6/30 (20.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 7/30 (23.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 8/30 (26.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 9/30 (30.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 10/30 (33.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 11/30 (36.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 12/30 (40.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 13/30 (43.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 14/30 (46.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 15/30 (50.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 16/30 (53.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 17/30 (56.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 18/30 (60.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 19/30 (63.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 20/30 (66.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 21/30 (70.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 22/30 (73.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 23/30 (76.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 24/30 (80.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 25/30 (83.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 26/30 (86.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 27/30 (90.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 28/30 (93.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 29/30 (96.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 30/30 (100.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> 
#> Completed 30 estimations in 0.0 minutes
head(res_multi)
#>    d dp  a event_time estimand     method           est           se
#> 1 25 26 25          0      APO DID_Female  5.856580e+04 1.148401e+04
#> 2 25 26 25          0      APO   DID_Male  6.598934e+04 1.025988e+04
#> 3 25 26 25          0      ATE DID_Female -1.820565e+04 1.146700e+04
#> 4 25 26 25          0      ATE   DID_Male  3.940978e+03 1.125230e+04
#> 5 25 26 25          0    theta DID_Female -3.108580e-01 1.409049e-01
#> 6 25 26 25          0    theta   DID_Male  5.972143e-02 1.753715e-01
#>            ci_l          ci_h          t            p n_female_treat
#> 1  3.605715e+04  8.107446e+04  5.0997699 3.400667e-07             40
#> 2  4.587999e+04  8.609870e+04  6.4317871 1.261123e-10             40
#> 3 -4.068098e+04  4.269676e+03 -1.5876554 1.123643e-01             40
#> 4 -1.811354e+04  2.599549e+04  0.3502374 7.261605e-01             40
#> 5 -5.870316e-01 -3.468443e-02 -2.2061549 2.737316e-02             40
#> 6 -2.840067e-01  4.034495e-01  0.3405424 7.334481e-01             40
#>   n_female_control n_male_treat n_male_control
#> 1               23           32             32
#> 2               23           32             32
#> 3               23           32             32
#> 4               23           32             32
#> 5               23           32             32
#> 6               23           32             32
```

## Citation

If you use childpen, please cite:

Leventer, Dor (2025). Identification of Child Penalties. Tel Aviv
University, Job Market Paper. <https://dorleventer.github.io/childpen>
