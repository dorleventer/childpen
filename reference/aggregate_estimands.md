# Aggregate estimands across treatment groups

Takes the stacked output of
[`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
and computes three aggregate estimands across treatment groups for each
event time:

## Usage

``` r
aggregate_estimands(
  results,
  weights = NULL,
  methods = c("DID_Female", "DID_Male", "TD", "NTD_Conv", "NTD_New"),
  include_pre = FALSE
)
```

## Arguments

- results:

  A `data.frame` as returned by
  [`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md),
  with at minimum the columns `d`, `event_time`, `estimand`, `method`,
  `est`, and `se`.

- weights:

  Named numeric vector of treatment-group weights (names must match the
  values of the `d` column coerced to character). Values are normalised
  to sum to 1 within each event_time × method cell, so you only need to
  supply relative weights. `NULL` (default) uses uniform weights over
  the treatment groups that have an estimate for that cell.

- methods:

  Character vector of methods to aggregate. Defaults to all five main
  methods.

- include_pre:

  Logical. If `TRUE`, also aggregate pre-treatment event times
  (`event_time < 0`). Default `FALSE`.

## Value

A `data.frame` with one row per `event_time` × `estimand` × `method` ×
`agg_type` combination, containing:

- `event_time` — event time

- `estimand` — `"APO"`, `"ATE"`, `"theta"`, or `"Delta_rho"`

- `method` — method name

- `agg_type` — one of `"avg_of_ratios"`, `"ratio_of_avgs"`,
  `"gender_ineq"`

- `est` — aggregate estimate

- `se` — standard error (see Details)

- `ci_l`, `ci_h` — 95 \\

- `n_groups` — number of treatment groups contributing

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
  treatment groups — the aggregate gender-inequality estimand.

**Standard errors.** Because the raw influence functions are not stored
in the `results` object, SEs are computed treating the group-specific
estimates as mutually independent.

For `avg_of_ratios`: \$\$\mathrm{SE}(\hat\theta\_{\text{Agg},1}) =
\sqrt{\sum_d w_d^2 \\ \hat\sigma_d^2}\$\$

For `ratio_of_avgs`, the delta method is applied to the ratio
\\\bar\mu\_{\text{ATE}} / \bar\mu\_{\text{APO}}\\: \$\$\mathrm{SE}
\approx \frac{1}{\bar\mu\_{\text{APO}}}
\sqrt{\mathrm{Var}(\bar\mu\_{\text{ATE}}) + \hat\theta\_{\text{Agg},2}^2
\\ \mathrm{Var}(\bar\mu\_{\text{APO}})}\$\$ where variances are again
computed via the independent-groups formula.

**Handling missing cells.** Not every treatment group produces an
estimate for every event time (due to `max_age` / `min_age` bounds). The
function operates on whichever groups are present for each cell and
reports how many via `n_groups`. If `weights` is supplied, only the
entries whose names appear in the observed treatment groups are used;
the remaining weights are dropped and the retained weights are
renormalised.

## Examples

``` r
# \donttest{
set.seed(1)
sim <- simulate_data(n_individuals = 500)
res <- multiple_treatment_group_analysis(sim, treatment_groups = 26:28,
                                         periods_post = 2, verbose = FALSE)
#>   Error for d=26, event_time=2: Empty subgroup: age=28, female=1, D=29
#>   Error for d=27, event_time=1: Empty subgroup: age=28, female=1, D=29
#>   Error for d=27, event_time=2: Empty subgroup: age=29, female=1, D=30
#>   Error for d=28, event_time=0: Empty subgroup: age=28, female=1, D=29
#>   Error for d=28, event_time=1: Empty subgroup: age=29, female=1, D=30
#>   Error for d=28, event_time=2: Empty subgroup: age=30, female=1, D=31
#>   Error for d=26, event_time=-5, dp=29: Empty subgroup: age=21, female=1, D=29
#>   Error for d=26, event_time=-4, dp=29: Empty subgroup: age=22, female=1, D=29
#>   Error for d=26, event_time=-3, dp=29: Empty subgroup: age=23, female=1, D=29
#>   Error for d=26, event_time=-2, dp=29: Empty subgroup: age=24, female=1, D=29
#>   Error for d=27, event_time=-5, dp=29: Empty subgroup: age=22, female=1, D=29
#>   Error for d=27, event_time=-5, dp=30: Empty subgroup: age=22, female=1, D=30
#>   Error for d=27, event_time=-4, dp=29: Empty subgroup: age=23, female=1, D=29
#>   Error for d=27, event_time=-4, dp=30: Empty subgroup: age=23, female=1, D=30
#>   Error for d=27, event_time=-3, dp=29: Empty subgroup: age=24, female=1, D=29
#>   Error for d=27, event_time=-3, dp=30: Empty subgroup: age=24, female=1, D=30
#>   Error for d=27, event_time=-2, dp=29: Empty subgroup: age=25, female=1, D=29
#>   Error for d=27, event_time=-2, dp=30: Empty subgroup: age=25, female=1, D=30
#>   Error for d=28, event_time=-5, dp=29: Empty subgroup: age=23, female=1, D=29
#>   Error for d=28, event_time=-5, dp=30: Empty subgroup: age=23, female=1, D=30
#>   Error for d=28, event_time=-5, dp=31: Empty subgroup: age=23, female=1, D=31
#>   Error for d=28, event_time=-4, dp=29: Empty subgroup: age=24, female=1, D=29
#>   Error for d=28, event_time=-4, dp=30: Empty subgroup: age=24, female=1, D=30
#>   Error for d=28, event_time=-4, dp=31: Empty subgroup: age=24, female=1, D=31
#>   Error for d=28, event_time=-3, dp=29: Empty subgroup: age=25, female=1, D=29
#>   Error for d=28, event_time=-3, dp=30: Empty subgroup: age=25, female=1, D=30
#>   Error for d=28, event_time=-3, dp=31: Empty subgroup: age=25, female=1, D=31
#>   Error for d=28, event_time=-2, dp=29: Empty subgroup: age=26, female=1, D=29
#>   Error for d=28, event_time=-2, dp=30: Empty subgroup: age=26, female=1, D=30
#>   Error for d=28, event_time=-2, dp=31: Empty subgroup: age=26, female=1, D=31
agg <- aggregate_estimands(res)
head(agg)
#>   event_time estimand     method      agg_type         est         se n_groups
#> 1          0    theta DID_Female avg_of_ratios -0.25869330 0.06697605        2
#> 2          1    theta DID_Female avg_of_ratios -0.25018121 0.07762588        1
#> 3          0    theta   DID_Male avg_of_ratios  0.02050512 0.09655764        2
#> 4          1    theta   DID_Male avg_of_ratios  0.18435456 0.16059788        1
#> 5          0    theta   NTD_Conv avg_of_ratios -0.27919842 0.11751243        2
#> 6          1    theta   NTD_Conv avg_of_ratios -0.43453578 0.17837449        1
#>         ci_l        ci_h
#> 1 -0.3899664 -0.12742024
#> 2 -0.4023279 -0.09803448
#> 3 -0.1687479  0.20975810
#> 4 -0.1304173  0.49912641
#> 5 -0.5095228 -0.04887407
#> 6 -0.7841498 -0.08492179
# }
```
