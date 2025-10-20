
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
#> Skipping install of 'childpen' from a github remote, the SHA1 (9af195cd) has not changed since last install.
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

set.seed(123)
sim_data <- simulate_data(n_individuals = 2000)
head(sim_data)
#>   id female age  D     Y_inf         Y
#> 1  1      1  20 39  4164.528  4164.528
#> 2  1      1  21 39  7904.255  7904.255
#> 3  1      1  22 39  6759.559  6759.559
#> 4  1      1  23 39 12002.566 12002.566
#> 5  1      1  24 39 17687.313 17687.313
#> 6  1      1  25 39 23578.168 23578.168
```

## Analyzing multiple treatment groups

The main function of the package provides estimates over a vector of
treatment groups, up to *periods_post* post treatment. Pre-treatment
periods used in validation test are set using *periods_pre*. The
anticipation period can be set by the researcher using *pre*, default is
one period before treatment.

``` r
# res_multi <- multiple_treatment_group_analysis(
#   sim_data,
#   treatment_groups = 25,
#   periods_post = 5,
#   periods_pre = 4,
#   pre = 1
# )
# 
# head(res_multi)
```

## Citation

If you use childpen, please cite:

Leventer, Dor (2025). Identification of Child Penalties. Tel Aviv
University, Job Market Paper. <https://dorleventer.github.io/childpen>
