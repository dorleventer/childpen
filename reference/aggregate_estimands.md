# Aggregate estimands across treatment groups

Takes the stacked output of
[`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
and computes three aggregate estimands across treatment groups for each
event time:

## Usage

``` r
aggregate_estimands(
  results,
  weights = "sample",
  methods = c("DID_Female", "DID_Male", "TD", "NTD_Conv", "NTD_New"),
  include_pre = FALSE
)
```

## Arguments

- results:

  A `data.frame` as returned by
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md),
  with at minimum the columns `d`, `event_time`, `estimand`, `method`,
  `est`, and `se`. If `results` carries influence-function data
  (attached automatically by
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)),
  standard errors account for shared control groups across treatment
  groups.

- weights:

  How to weight treatment groups. One of:

  - `"sample"` (default): use sample-proportion weights as in Leventer
    (2025). Within-gender weights \\w\_{g,d} = n\_{g,d}/\sum
    n\_{g,\tilde d}\\ are used for `DID_Female` and `DID_Male`;
    cross-gender weights \\w_d = n_d / \sum n\_{\tilde d}\\ for `TD`,
    `NTD_Conv`, and `NTD_New`. Standard errors account for estimation of
    the weights.

  - `NULL`: uniform weights (equal weight per group).

  - A named numeric vector: custom fixed weights (names = treatment
    groups as characters). Values are renormalised to sum to 1.

- methods:

  Character vector of methods to aggregate. Defaults to all five main
  methods.

- include_pre:

  Logical. If `TRUE`, also aggregate pre-treatment event times
  (`event_time < 0`). Default `FALSE`.

## Value

A `data.frame` with one row per `event_time` by `estimand` by `method`
by `agg_type` combination, containing:

- `event_time` – event time

- `estimand` – `"APO"`, `"ATE"`, `"theta"`, or `"Delta_rho"`

- `method` – method name

- `agg_type` – one of `"avg_of_ratios"`, `"ratio_of_avgs"`,
  `"gender_ineq"`

- `est` – aggregate estimate

- `se` – standard error (see Details)

- `ci_l`, `ci_h` – 95 \\

- `n_groups` – number of treatment groups contributing

## Details

- **avg_of_ratios** (\\\theta\_{\text{Agg},1}\\):

  Weighted average of the group-specific normalised effects \\\theta(g,
  d, d+e)\\ across treatment groups \\d\\. This is the preferred
  estimand because it averages effects that are already scaled by each
  group's baseline.

- **ratio_of_avgs** (\\\theta\_{\text{Agg},2}\\):

  Ratio of the weighted-average ATE to the weighted-average APO. The
  implicit weight on each group is \\p_d \cdot \text{APO}\_d\\, giving
  higher-earning groups more influence.

- **gender_ineq** (\\\Delta\rho\_{\text{Agg}}\\):

  Weighted average of `NTD_New` (estimand == "Delta_rho") across
  treatment groups – the aggregate gender-inequality estimand.

**Standard errors.** When the `results` object carries
influence-function (IF) data from
[`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md),
aggregate SEs account for dependence across treatment groups caused by
shared control individuals.

With `weights = "sample"`, the IF additionally accounts for estimation
of the weights, following the formula in Leventer (2025, Appendix G):
\$\$\psi\_{A(e)} = \sum_d \left\[ w_d\\\psi\_{B_d} + \frac{B_d -
A(e)}{M}\\\psi\_{p_d} \right\]\$\$ where \\M = \sum_d p_d\\ and
\\\psi\_{p_d}\\ is the IF of the group proportion.

With fixed weights (`NULL` or a named vector), the second term drops out
and the IF reduces to \\\sum_d w_d\\\psi\_{B_d}\\.

For `ratio_of_avgs`, the delta method is applied to the ratio
\\\bar\mu\_{\text{ATE}} / \bar\mu\_{\text{APO}}\\ using the aggregate
IFs for the numerator and denominator.

If IF data is not available (e.g., when the user supplies a manually
constructed results table), SEs are computed under an independence
approximation with a warning.

**Handling missing cells.** Not every treatment group produces an
estimate for every event time (due to `max_age` / `min_age` bounds). The
function operates on whichever groups are present for each cell and
reports how many via `n_groups`. If `weights` is supplied as a named
vector, only the entries whose names appear in the observed treatment
groups are used; the remaining weights are dropped and the retained
weights are renormalised.

## Examples

``` r
# \donttest{
set.seed(1)
sim <- simulate_data(n_individuals = 500)
res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:25,
                                         periods_post = 2, verbose = FALSE)
#>   Error for d=24, event_time=-5, dp=25: Empty subgroup: age=19, female=1, D=24
#>   Error for d=24, event_time=-5, dp=26: Empty subgroup: age=19, female=1, D=24
#>   Error for d=24, event_time=-5, dp=27: Empty subgroup: age=19, female=1, D=24
agg <- aggregate_estimands(res)
head(agg)
#>   event_time estimand     method      agg_type         est         se n_groups
#> 1          0    theta DID_Female avg_of_ratios -0.29648428 0.02688094        2
#> 2          1    theta DID_Female avg_of_ratios -0.27864063 0.02450991        2
#> 3          2    theta DID_Female avg_of_ratios -0.26867246 0.02001048        2
#> 4          0    theta   DID_Male avg_of_ratios -0.02789507 0.03252366        2
#> 5          1    theta   DID_Male avg_of_ratios -0.02730183 0.03285187        2
#> 6          2    theta   DID_Male avg_of_ratios -0.07414387 0.03154374        2
#>          ci_l        ci_h
#> 1 -0.34917093 -0.24379764
#> 2 -0.32668006 -0.23060119
#> 3 -0.30789301 -0.22945192
#> 4 -0.09164144  0.03585129
#> 5 -0.09169150  0.03708783
#> 6 -0.13596961 -0.01231814
# }
```
