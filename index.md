# childpen

**childpen: Child Penalties Estimators & Simulation Tools**

> This package accompanies my job market paper:  
> **Leventer, Dor (2025).** *Identification of Child Penalties.*  
> [arXiv:2602.07486](https://arxiv.org/abs/2602.07486)

- 🧪 DID / TD / NTD estimators (single & multiple treatment groups)
- 🧰 Simulation tools  
- 💻 **GitHub:** <https://github.com/dorleventer/childpen>  
- 🌐 **Website:** <https://dorleventer.github.io/childpen>

------------------------------------------------------------------------

## Roadmap

**Package functions**

**Estimation of single 2×2** —
[`single_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)

**Wrapper for multiple 2×2** —
[`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)

**Data simulation** —
[`simulate_data()`](https://dorleventer.github.io/childpen/reference/simulate_data.md)

**Aggregation over multiple groups** —
[`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)

**Explainers**

**Data simulation** —
[vignette](https://dorleventer.github.io/childpen/articles/simulation.html)

**Intuition for NTD bias** —
[vignette](https://dorleventer.github.io/childpen/articles/NTD-identification.html)

**DID estimation** —
[vignette](https://dorleventer.github.io/childpen/articles/DID-estimation.html)

**TD bias** —
[vignette](https://dorleventer.github.io/childpen/articles/TD-identification.html)

**TD / NTD estimation** —
[vignette](https://dorleventer.github.io/childpen/articles/TD-NTD-estimation.html)

**Validation tests** —
[vignette](https://dorleventer.github.io/childpen/articles/validation_tests.html)

**Aggregate estimates** —
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
