
<!-- README.md is generated from README.Rmd. Please edit that file -->

# childpen <img src="man/figures/logo.png" align="right" height="120"/>

<!-- badges: start -->

<!-- badges: end -->

### Identification of Child Penalties: Estimators and Simulation Tools

The **`childpen`** package implements the core estimators and
data-preparation utilities developed in the paper:

> **Leventer, Dor (2025)**.  
> *Identification of Child Penalties:*  
> Tel Aviv University, Job Market Paper.  
> \[link to paper or DOI once public\]

The package provides: - **Formal implementations** of
Difference-in-Differences (DID), Triple Differences (TD), and Normalized
Event-Study (NTD) estimators used in child-penalty applications.  
- **Alternative identification frameworks**, including conditional
DID/TD and null-effect identification strategies.  
- **Utility functions** for influence-function–based standard errors,
balanced-panel construction, and data preparation.  
- **Simulation tools** to generate artificial data consistent with
theoretical child-penalty mechanisms.

------------------------------------------------------------------------

## Installation

Install the latest development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("dorleventer/childpen")
#> Using GitHub PAT from the git credential store.
#> Skipping install of 'childpen' from a github remote, the SHA1 (1b96fbe8) has not changed since last install.
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

sim_data <- simulate_data(n_individuals = 10000, seed = 42)
head(sim_data)
#>   id female age  D     Y_inf         Y
#> 1  1      1  20 34  5409.207  5409.207
#> 2  1      1  21 34  4111.729  4111.729
#> 3  1      1  22 34  8901.461  8901.461
#> 4  1      1  23 34 19872.782 19872.782
#> 5  1      1  24 34 22623.541 22623.541
#> 6  1      1  25 34 29288.630 29288.630
```

## Analyzing single 2-by-2s

The work behind the scenes is done by the function below, which
estimates all relevant parameters for a single 2-by-2 comparison.

``` r
single_treatment_group_analysis(sim_data, d = 25, dp = 26, a = 25, pre = 1) |> head()
#>   estimand     method           est           se n_female_treat
#> 1      APO DID_Female  6.952063e+04 4.575281e+03            341
#> 2      APO   DID_Male  7.046731e+04 4.219647e+03            341
#> 3      ATE DID_Female -1.919906e+04 4.366312e+03            341
#> 4      ATE   DID_Male -1.362064e+02 4.560543e+03            341
#> 5    theta DID_Female -2.761635e-01 4.951042e-02            341
#> 6    theta   DID_Male -1.932901e-03 6.464362e-02            341
#>   n_female_control n_male_treat n_male_control
#> 1              296          302            314
#> 2              296          302            314
#> 3              296          302            314
#> 4              296          302            314
#> 5              296          302            314
#> 6              296          302            314
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
#> Progress: 1/30 (3.3%) | Elapsed: 0.0 min | Remaining: ~0.4 min
#> Progress: 2/30 (6.7%) | Elapsed: 0.0 min | Remaining: ~0.4 min
#> Progress: 3/30 (10.0%) | Elapsed: 0.0 min | Remaining: ~0.3 min
#> Progress: 4/30 (13.3%) | Elapsed: 0.0 min | Remaining: ~0.3 min
#> Progress: 5/30 (16.7%) | Elapsed: 0.1 min | Remaining: ~0.3 min
#> Progress: 6/30 (20.0%) | Elapsed: 0.1 min | Remaining: ~0.3 min
#> Progress: 7/30 (23.3%) | Elapsed: 0.1 min | Remaining: ~0.3 min
#> Progress: 8/30 (26.7%) | Elapsed: 0.1 min | Remaining: ~0.3 min
#> Progress: 9/30 (30.0%) | Elapsed: 0.1 min | Remaining: ~0.2 min
#> Progress: 10/30 (33.3%) | Elapsed: 0.1 min | Remaining: ~0.2 min
#> Progress: 11/30 (36.7%) | Elapsed: 0.1 min | Remaining: ~0.2 min
#> Progress: 12/30 (40.0%) | Elapsed: 0.1 min | Remaining: ~0.2 min
#> Progress: 13/30 (43.3%) | Elapsed: 0.1 min | Remaining: ~0.2 min
#> Progress: 14/30 (46.7%) | Elapsed: 0.2 min | Remaining: ~0.2 min
#> Progress: 15/30 (50.0%) | Elapsed: 0.2 min | Remaining: ~0.2 min
#> Progress: 16/30 (53.3%) | Elapsed: 0.2 min | Remaining: ~0.2 min
#> Progress: 17/30 (56.7%) | Elapsed: 0.2 min | Remaining: ~0.1 min
#> Progress: 18/30 (60.0%) | Elapsed: 0.2 min | Remaining: ~0.1 min
#> Progress: 19/30 (63.3%) | Elapsed: 0.2 min | Remaining: ~0.1 min
#> Progress: 20/30 (66.7%) | Elapsed: 0.2 min | Remaining: ~0.1 min
#> Progress: 21/30 (70.0%) | Elapsed: 0.2 min | Remaining: ~0.1 min
#> Progress: 22/30 (73.3%) | Elapsed: 0.2 min | Remaining: ~0.1 min
#> Progress: 23/30 (76.7%) | Elapsed: 0.3 min | Remaining: ~0.1 min
#> Progress: 24/30 (80.0%) | Elapsed: 0.3 min | Remaining: ~0.1 min
#> Progress: 25/30 (83.3%) | Elapsed: 0.3 min | Remaining: ~0.1 min
#> Progress: 26/30 (86.7%) | Elapsed: 0.3 min | Remaining: ~0.0 min
#> Progress: 27/30 (90.0%) | Elapsed: 0.3 min | Remaining: ~0.0 min
#> Progress: 28/30 (93.3%) | Elapsed: 0.3 min | Remaining: ~0.0 min
#> Progress: 29/30 (96.7%) | Elapsed: 0.3 min | Remaining: ~0.0 min
#> Progress: 30/30 (100.0%) | Elapsed: 0.3 min | Remaining: ~0.0 min
#> 
#> Completed 30 estimations in 0.3 minutes
head(res_multi)
#>    d dp  a event_time estimand     method           est           se
#> 1 25 26 25          0      APO DID_Female  6.952063e+04 4.575281e+03
#> 2 25 26 25          0      APO   DID_Male  7.046731e+04 4.219647e+03
#> 3 25 26 25          0      ATE DID_Female -1.919906e+04 4.366312e+03
#> 4 25 26 25          0      ATE   DID_Male -1.362064e+02 4.560543e+03
#> 5 25 26 25          0    theta DID_Female -2.761635e-01 4.951042e-02
#> 6 25 26 25          0    theta   DID_Male -1.932901e-03 6.464362e-02
#>            ci_l          ci_h           t            p n_female_treat
#> 1  6.055308e+04  7.848818e+04 15.19483147 3.826464e-52            341
#> 2  6.219680e+04  7.873782e+04 16.69981011 1.314826e-62            341
#> 3 -2.775703e+04 -1.064109e+04 -4.39708899 1.097124e-05            341
#> 4 -9.074872e+03  8.802459e+03 -0.02986626 9.761737e-01            341
#> 5 -3.732039e-01 -1.791231e-01 -5.57788631 2.434587e-08            341
#> 6 -1.286344e-01  1.247686e-01 -0.02990088 9.761461e-01            341
#>   n_female_control n_male_treat n_male_control
#> 1              296          302            314
#> 2              296          302            314
#> 3              296          302            314
#> 4              296          302            314
#> 5              296          302            314
#> 6              296          302            314
```

## Citation

If you use childpen, please cite:

Leventer, Dor (2025). Identification of Child Penalties. Tel Aviv
University, Job Market Paper. <https://dorleventer.github.io/childpen>
