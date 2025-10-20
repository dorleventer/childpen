
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
#> Downloading GitHub repo dorleventer/childpen@HEAD
#> 
#> ── R CMD build ─────────────────────────────────────────────────────────────────
#>      checking for file ‘/private/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T/RtmpTPDUNd/remoteseeef562fa891/dorleventer-childpen-b5b134e/DESCRIPTION’ ...  ✔  checking for file ‘/private/var/folders/ls/2dzknzwx5q1fdfh311w86m3h0000gn/T/RtmpTPDUNd/remoteseeef562fa891/dorleventer-childpen-b5b134e/DESCRIPTION’
#>   ─  preparing ‘childpen’:
#>      checking DESCRIPTION meta-information ...  ✔  checking DESCRIPTION meta-information
#>   ─  checking for LF line-endings in source and make files and shell scripts
#>   ─  checking for empty or unneeded directories
#>   ─  building ‘childpen_0.0.0.9000.tar.gz’
#>      
#> 
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
res_multi <- multiple_treatment_group_analysis(
  sim_data,
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
#>   Error for d=25, event_time=0: object 'DT' not found
#>   Error for d=25, event_time=1: object 'DT' not found
#>   Error for d=25, event_time=2: object 'DT' not found
#>   Error for d=25, event_time=3: object 'DT' not found
#>   Error for d=25, event_time=4: object 'DT' not found
#>   Error for d=25, event_time=5: object 'DT' not found
#>   Error for d=25, event_time=-5, dp=26: object 'DT' not found
#>   Error for d=25, event_time=-5, dp=27: object 'DT' not found
#>   Error for d=25, event_time=-5, dp=28: object 'DT' not found
#>   Error for d=25, event_time=-5, dp=29: object 'DT' not found
#>   Error for d=25, event_time=-5, dp=30: object 'DT' not found
#>   Error for d=25, event_time=-5, dp=31: object 'DT' not found
#>   Error for d=25, event_time=-4, dp=26: object 'DT' not found
#>   Error for d=25, event_time=-4, dp=27: object 'DT' not found
#>   Error for d=25, event_time=-4, dp=28: object 'DT' not found
#>   Error for d=25, event_time=-4, dp=29: object 'DT' not found
#>   Error for d=25, event_time=-4, dp=30: object 'DT' not found
#>   Error for d=25, event_time=-4, dp=31: object 'DT' not found
#>   Error for d=25, event_time=-3, dp=26: object 'DT' not found
#>   Error for d=25, event_time=-3, dp=27: object 'DT' not found
#>   Error for d=25, event_time=-3, dp=28: object 'DT' not found
#>   Error for d=25, event_time=-3, dp=29: object 'DT' not found
#>   Error for d=25, event_time=-3, dp=30: object 'DT' not found
#>   Error for d=25, event_time=-3, dp=31: object 'DT' not found
#>   Error for d=25, event_time=-2, dp=26: object 'DT' not found
#>   Error for d=25, event_time=-2, dp=27: object 'DT' not found
#>   Error for d=25, event_time=-2, dp=28: object 'DT' not found
#>   Error for d=25, event_time=-2, dp=29: object 'DT' not found
#>   Error for d=25, event_time=-2, dp=30: object 'DT' not found
#>   Error for d=25, event_time=-2, dp=31: object 'DT' not found
#> 
#> Completed 0 estimations in 0.0 minutes
#> 
#> No valid result rows produced. Returning empty data.frame.

head(res_multi)
#> data frame with 0 columns and 0 rows
```

## Citation

If you use childpen, please cite:

Leventer, Dor (2025). Identification of Child Penalties. Tel Aviv
University, Job Market Paper. <https://dorleventer.github.io/childpen>
