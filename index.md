# childpen

> This package accompanies my job market paper: **Leventer, Dor
> (2025).** *Identification of Child Penalties.*

- 🧪 DID / TD / NTD estimators (single & multiple treatment groups)
- 📄 **Paper:** [arXiv:2602.07486](https://arxiv.org/abs/2602.07486)
- 💻 **GitHub:** <https://github.com/dorleventer/childpen>
- 🌐 **Website:** <https://dorleventer.github.io/childpen/>

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

**Estimation (DID, TD, NTD)** —
[vignette](https://dorleventer.github.io/childpen/articles/estimation.html)

**NTD identification** —
[vignette](https://dorleventer.github.io/childpen/articles/NTD-identification.html)

**Validation tests** —
[vignette](https://dorleventer.github.io/childpen/articles/validation_tests.html)

**Aggregate estimands** —
[vignette](https://dorleventer.github.io/childpen/articles/aggregate-estimands.html)

------------------------------------------------------------------------

## Installation

Install the latest development version from GitHub:

``` r

# install.packages("remotes")
remotes::install_github("dorleventer/childpen")
```
